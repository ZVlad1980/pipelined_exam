create or replace package body pay_gfnpo_pkg is
  
  GC_UNIT_NAME   constant varchar2(32) := $$PLSQL_UNIT;
  
  GC_RM_DEBUG    constant varchar2(1) := 'D';
  --GC_RM_NORMAL   constant varchar2(1) := 'N';
  
  GC_RUN_MODE    constant varchar2(1)  := GC_RM_DEBUG;
  
  GC_ST_SUCCESS  constant number := 0;
  GC_ST_ERROR    constant number := 3;
  
  GC_LM_ASSIGNMENTS  constant number := 1;
  
  GC_OPS_COMPANY         constant number := 1001;   -- вкладчик ќѕ—
  GC_OPS_SCHEME          constant number := 7;      -- схема ќѕ—
  
  GC_CONTRACT_PEN        constant number := 6;      -- контракт-пенсионное соглашение
  
  GC_ASGPC_LIFE          constant number := 5054;  -- начисление, код ѕќ∆»«Ќ≈ЌЌјя ѕ≈Ќ—»я 
  GC_ASGPC_TERM          constant number := 5051;  -- начисление, код —–ќ„Ќјя ѕ≈Ќ—»я
  /*GC_ASGPC_LUMP          constant number := 5052;  -- начисление, код ≈ƒ»Ќќ¬–≈ћ≈ЌЌјя ¬џѕЋј“ј
  GC_ASGPC_AUX           constant number := 5053;  -- начисление, код ƒќѕќЋЌ»“≈Ћ№Ќјя ≈¬
  GC_ASGPC_ASSIGNEE      constant number := 5122;  -- начисление, код —”ћћј ѕ–ј¬ќѕ–≈≈ћЌ» ”
  GC_ASGPC_WITHHOLDING   constant number := 7604;  -- начисление удержаний
  */
  GC_ASG_OP_TYPE         constant number := 2;      -- начисление, код типа дл€ записей начислени€ пенсии
  
  --GC_PAST_NEW        constant number := 0;      -- статус соглашени€ на выплату - новое, готово к проверкам
  GC_PAST_PAY        constant number := 1;      -- статус соглашени€ на выплату - фаза выплат (ѕЋј“»“№)
  --GC_PAST_STOP       constant number := 2;      -- статус соглашени€ на выплату - об€зательства выполнены (Ќ≈ ѕЋј“»“№)
  --GC_PAST_LIST       constant number := 6;      -- статус соглашени€ на выплату - проверено, подготовлено к выплате, включено в список на 1 выплату
  
  GC_ACCT_TYPE_SSPV  constant number := 4;      -- тип солидарного счета
  
  --GC_CNTRCT_ALL      constant varchar2(10) := 'ALL';  --
  --GC_CNTRCT_LIFE     constant varchar2(10) := 'LIVE'; --пожизненна€ пенси€
  --GC_CNTRCT_TERM     constant varchar2(10) := 'TERM'; --ежемес€чные выплаты по срокам
  
  GC_POFLTR_COMPANY  constant varchar2(10) := 'COMPANY';
  GC_POFLTR_CONTRACT constant varchar2(10) := 'CONTRACT';
  
  G_LOG_MARK     number;
  G_LOG_TOKEN    number;
  
  
  type g_pay_order_typ is record(
    pay_order_id       number,
    operation_date     pay_orders.operation_date%type,
    payment_period     pay_orders.payment_period%type, --old: charges_period
    payment_freqmask   pay_orders.payment_freqmask%type,
    scheduled_date     pay_orders.scheduled_date%type,
    calculation_date   pay_orders.calculation_date%type,
    fk_pay_order_type  pay_orders.fk_pay_order_type%type,
    --
    charges_month      number,
    charges_quarter    number,
    charges_halfyear   number,
    charges_year       number,
    --
    last_day_prev_year date,
    last_day_quarter   date,
    last_day_halfyear  date,
    last_day_year      date,
    last_day_month     date,
    --
    app_fond_id        number,
    oper_id            number
  );
  
  type g_acct_sspv_tbl_typ is table of number index by pls_integer;
  g_acct_sspv_tbl g_acct_sspv_tbl_typ;
  
  type g_error_typ is record (
    error_msg         varchar2(4000),
    critical          boolean,
    error_stack       varchar2(2000),
    error_backtrace   varchar2(2000),
    call_stack        varchar2(2000)
  );
  type g_errors_typ is table of g_error_typ index by pls_integer;
  
  g_errors g_errors_typ;
  
  
  procedure put_line(
    p_msg varchar2,
    p_nl  boolean default true
  ) is
  begin
    if GC_RUN_MODE <> GC_RM_DEBUG then
      return;
    end if;
    
    if p_nl then
      dbms_output.put_line(p_msg);
    else
      dbms_output.put(p_msg);
    end if;
  end put_line;
  
  
  
  procedure log_write(
    p_msg_level  number, 
    p_msg        varchar2
  ) as
    c_chunk_size constant int := 256;
    l_offset     int;
  begin
    
    l_offset := 1;
    
    while l_offset < length(p_msg) loop
      log_pkg.WriteAtMark(
        pLogMark  => G_LOG_MARK,
        pLogToken => G_LOG_TOKEN,
        pWrnLevel => p_msg_level,
        pMsgInfo  => substr(p_msg, l_offset, c_chunk_size)
      );
      
      l_offset := l_offset + c_chunk_size;
      
    end loop;
    
    put_line(p_msg);
    
  end log_write;
  
  
  
  procedure fix_exception(
    p_line     int,
    p_msg      varchar2 default null
  ) is
    l_idx int;
  begin
    
    l_idx := g_errors.count + 1;
    
    g_errors(l_idx).error_msg       := GC_UNIT_NAME || '(' || p_line || '): ' || nvl(p_msg, sqlerrm);
    g_errors(l_idx).error_stack     := dbms_utility.format_error_stack;
    g_errors(l_idx).error_backtrace := dbms_utility.format_error_backtrace;
    g_errors(l_idx).call_stack      := dbms_utility.format_call_stack;
    
    if GC_RUN_MODE = GC_RM_DEBUG then
      put_line(g_errors(l_idx).error_msg      );
      put_line(g_errors(l_idx).error_stack    );
      put_line(g_errors(l_idx).error_backtrace);
      put_line(g_errors(l_idx).call_stack     );
    end if;
    
  end fix_exception;
  
  
  
  function get_error_msg return varchar2 is
  begin
    return case when not g_errors.exists(1) then null else g_errors(1).error_msg end;
  end get_error_msg;
  
  
  
  procedure init_errors(
    p_log_mark  number,
    p_log_token number default null
  ) is
  begin
    
    g_errors.delete();
    G_LOG_MARK  := p_log_mark ;
    G_LOG_TOKEN := p_log_token;
    
  end init_errors;
  
  
  /**
   *
   */
  function get_pay_order(
    p_pay_order_id number,
    p_oper_id   number
  ) return g_pay_order_typ is
    l_result g_pay_order_typ;
  begin
    
    Select po.operation_date, 
           trunc(po.payment_period, 'DD'), 
           po.payment_freqmask, 
           po.scheduled_date, 
           po.calculation_date, 
           po.fk_pay_order_type
    into   l_result.operation_date, 
           l_result.payment_period, 
           l_result.payment_freqmask,
           l_result.scheduled_date, 
           l_result.calculation_date,
           l_result.fk_pay_order_type
    from   pay_orders po
    where  po.fk_document = p_pay_order_id;
  
    l_result.pay_order_id        := p_pay_order_id;
    l_result.charges_month       := extract(month from l_result.payment_period);
    l_result.charges_quarter     := ceil(l_result.charges_month / 3);
    l_result.charges_halfyear    := ceil(l_result.charges_month / 6);
    l_result.charges_year        := extract(year from l_result.payment_period);
    
    l_result.last_day_prev_year  := trunc(l_result.payment_period, 'YYYY') - 1;
    l_result.last_day_quarter    := add_months(l_result.last_day_prev_year, 3 * l_result.charges_quarter);  -- последний день квартала  ;
    l_result.last_day_halfyear   := add_months(l_result.last_day_prev_year, 6 * l_result.charges_halfyear);  -- последний день полугоди€ ;
    l_result.last_day_year       := to_date(l_result.charges_year || '1231', 'yyyymmdd');
    l_result.last_day_month      := last_day(l_result.payment_period);
    --
    l_result.oper_id             := p_oper_id;
    l_result.app_fond_id         := APP_GLOBALS.FondContragentId();
    
    return l_result;
  exception
    when others then
      fix_exception(
        $$PLSQL_LINE,
        'get_pay_order(' || p_pay_order_id || '): ошибка инициализации данных ордера.'
      );
      raise;
  end;
  
  procedure init is
  begin
    log_write(log_pkg.C_LVL_INF, 'ќпределение счетов ——ѕ¬ дл€ 1 и 6 схем:');
    
    for a in (
      select ac.id, ac.fk_scheme
      from   accounts ac
      where  ac.fk_acct_type = GC_ACCT_TYPE_SSPV
      and    ac.fk_scheme in (1, 6)
    ) loop
      g_acct_sspv_tbl(a.fk_scheme) := a.id;
    end loop;
    
    if not g_acct_sspv_tbl.exists(1) then
      g_acct_sspv_tbl(1) := 10042;
      log_write(log_pkg.C_LVL_WRN, '  ƒл€ 1 схемы счет не определен! ”становлен счет ——ѕ¬ дл€ ќѕ—!');
    end if;
    
    if not g_acct_sspv_tbl.exists(6) then
      g_acct_sspv_tbl(6) := 10042;
      log_write(log_pkg.C_LVL_WRN, '  ƒл€ 6 схемы счет не определен! ”становлен счет ——ѕ¬ дл€ ќѕ—!');
    end if;
    
  end init;
  
  function add_month$(
    p_date   date,
    p_months int
  ) return date is
  begin
    return add_months(p_date, p_months);
  end add_month$;
  
  /**
   */
  function get_pension_amount(
    p_fk_contract number,
    p_paydate     date
  ) return number is
  begin
    return 10;
  end get_pension_amount;
  
  /**
   *
   */
  function get_agreements_cur(
    p_pay_order        g_pay_order_typ,
    p_contract_type    varchar2, --'ALL' / 'LIFE' / 'TERM'
    p_filter_company   varchar2,
    p_filter_contract  varchar2
  ) return sys_refcursor is
    l_result  sys_refcursor;
    l_request varchar2(32767);
  begin
    --
    l_request := 'select pa.fk_contract,
             pa.fk_base_contract,
             bco.fk_account   fk_debit,
             co.fk_account    fk_credit,
             co.fk_scheme,
             co.fk_contragent,
             pa.effective_date,
             pa.expiration_date,
             pa.amount,
             last_day(coalesce(p.deathdate, :1)) last_pay_date
      from   contracts          co,
             pension_agreements pa,
             contracts          bco,
             people             p
      where  1=1
      and    bco.fk_document = pa.fk_base_contract
      and    p.fk_contragent = co.fk_contragent 
      and    co.fk_document = pa.fk_contract
      and    co.fk_company <> ' || GC_OPS_COMPANY || '
      and    co.fk_scheme <>  ' || GC_OPS_SCHEME || '
      and    co.fk_cntr_type = ' || GC_CONTRACT_PEN || '
      and    pa.state = ' || GC_PAST_PAY || '
      and    not exists (
               select 1
               from   registry_details rd,
                      registries       rg,
                      registry_types   rt
               where  rt.stop_pays = 1
               and    rt.id = rg.fk_registry_type
               and    rg.id = rd.fk_registry
               and    rd.fk_contract = pa.fk_base_contract
             )
      and    pa.effective_date <= :2
      and    pa.isarhv = 0' || chr(10) ||
    case 
      when p_filter_contract = 'Y' then
        'and pa.fk_contract in (
           select pof.filter_value
           from   pay_order_filters pof
           where  pof.filter_code = :3
           and    pof.fk_pay_order = :4)'
      when p_filter_company  = 'Y' then
        'and co.fk_company in (
           select pof.filter_value
           from   pay_order_filters pof
           where  pof.filter_code = :3
           and    pof.fk_pay_order = :4)'
    end || chr(10) || 
    case
      when p_contract_type = GC_ASGPC_LIFE then
        'and pa.expiration_date is null'
      when p_contract_type = GC_ASGPC_TERM then
        'and pa.expiration_date is not null'
    end
    ;
    --
    put_line(l_request);
    
    if p_filter_contract = 'Y' or p_filter_company = 'Y' then
      open l_result for l_request 
        using p_pay_order.last_day_month, 
              p_pay_order.last_day_month,
              case when p_filter_contract = 'Y' then GC_POFLTR_CONTRACT when p_filter_company = 'Y' then GC_POFLTR_COMPANY end,
              p_pay_order.pay_order_id;
    else
      open l_result for l_request 
        using p_pay_order.last_day_month, 
              p_pay_order.last_day_month;
    end if;
    
    return l_result;
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'get_agreements_cur(' || p_pay_order.pay_order_id || ', ' || p_contract_type || ', ' || p_filter_company || ', ' || p_filter_contract || ') failed');
      raise;
  end;
  
  /**
   *
   */
  procedure fill_charges_pension(
    p_pay_order        g_pay_order_typ,
    p_agreements_cur   sys_refcursor
  ) is
    type l_agreements_typ is record (
      fk_contract           pension_agreements.fk_contract%type,
      fk_base_contract      pension_agreements.fk_base_contract%type,
      fk_debit              contracts.fk_account%type,
      fk_credit             contracts.fk_account%type,
      fk_scheme             contracts.fk_scheme%type,
      fk_contragent         contracts.fk_contragent%type,
      effective_date        pension_agreements.effective_date%type,
      expiration_date       pension_agreements.expiration_date%type,
      amount                pension_agreements.amount%type,
      last_pay_date         date
    );
    l_agreement l_agreements_typ;
    -- список изменений к —оглашению
    cursor l_addendums_cur(
      p_effective_date date,
      p_amount         number,
      p_fk_contract    number
    ) is
      select p.alt_date_begin,
             p.amount,
             p.fk_provacct
      from   (select  pa.alt_date_begin,    -- дата изменени€
                      pa.amount,                  -- размер пенсии на это число
                      pa.serialno,                -- номер изменени€
                      pa.fk_provacct,
                      max(pa.serialno) over(partition by pa.alt_date_begin) maxno                    
              from    (select p_effective_date alt_date_begin,
                              p_amount         amount, 
                              0                serialno,
                              null             fk_provacct
                       from   dual
                      union
                       Select paa.alt_date_begin  alt_date_begin,
                              paa.amount          amount,  
                              paa.serialno        serialno,
                              paa.fk_provacct
                       from   pension_agreement_addendums paa -- из доп.соглашений
                       where  paa.canceled = 0
                       and    paa.fk_pension_agreement = p_fk_contract
                      ) pa
              ) p
      where p.serialno = p.maxno
      order by p.alt_date_begin;
    
    cursor l_months_cur(
      p_fk_contract     number,
      p_fk_credit       number,
      p_pay_code        number,
      p_first_month     date,
      p_months_cnt      int,
      p_last_date       date
    ) is
      select m.paydate
      from   -- мес€цы начислени€ основной пожизненной пенсии
             (select a.paydate
              from   assignments a
              where  a.fk_credit = p_fk_credit
              and    a.fk_paycode = p_pay_code
             ) a,
             -- мес€цы с ƒЌ¬ до текущего
             (select add_months(p_first_month, level - 1) paydate
              from   dual  
              connect by level <= p_months_cnt
             ) m
      where 1=1
      and   a.paydate(+) = m.paydate
      and   a.paydate is null  -- выбираем мес€цы, в которых не было начислениий основной пенсии
      and   m.paydate < p_last_date -- и мес€ц выплаты должен быть не позже мес€цы смерти
      -- и эти мес€цы не попали в периоды действующих ограничений на выплаты пенсий
      and not exists (
        select 1
        from   pay_restrictions pr
        where  pr.fk_document_cancel is null
        and    pr.fk_doc_with_acct = p_fk_contract
        and    pr.effective_date <= m.paydate
        and    m.paydate <= nvl(pr.expiration_date, p_last_date)
      );
  
  
   l_addendum l_addendums_cur%rowtype;
   
   l_first_month       date;
   l_months_cnt        int;
   l_amount            number;
   l_month_pay         number;
   l_day               number;
   l_day2              number;
   l_day_a             number;

   l_assignment        assignments%rowtype;
   l_assignment_templ  assignments%rowtype;
   
  begin
    
    assignments_api.init;
  
    l_assignment_templ.fk_doc_with_action := p_pay_order.pay_order_id;
    l_assignment_templ.fk_asgmt_type      := GC_ASG_OP_TYPE;  -- код "начисление пенсии"
    
    
    --for pa in l_agreements_cur(p_pay_order.pay_order_id, p_pay_order.last_day_month) loop
    loop
      fetch p_agreements_cur into l_agreement;
      exit when p_agreements_cur%notfound;
      
      l_assignment_templ.fk_doc_with_acct := l_agreement.fk_contract;
      l_assignment_templ.serv_doc         := l_agreement.fk_contract;
      l_assignment_templ.fk_credit        := l_agreement.fk_credit;
      l_assignment_templ.fk_scheme        := l_agreement.fk_scheme;
      l_assignment_templ.fk_contragent    := l_agreement.fk_contragent;
      l_assignment_templ.fk_paycode       := case when l_agreement.expiration_date is null then GC_ASGPC_LIFE else GC_ASGPC_TERM end;  -- тип начисл€емой пенсии (пожизненна€/срочна€)
      --l_assignment_templ.comments         := 'Ќачисление пенсии. ќѕ— ѕожизненна€ выплата.';
      
      l_assignment_templ.fk_debit         := l_agreement.fk_debit;
      
      if l_assignment_templ.fk_debit is null and l_assignment_templ.fk_scheme in (1, 6) then
        l_assignment_templ.fk_debit := g_acct_sspv_tbl(l_assignment_templ.fk_scheme);
      end if;
      
      if l_assignment_templ.fk_debit is null then
        log_write(log_pkg.C_LVL_ERR, ' Ќе определен счет-источник средств, контракт: ' || l_agreement.fk_base_contract);
        continue;
      end if;
      
      open l_addendums_cur(l_agreement.effective_date, l_agreement.amount, l_agreement.fk_contract);
      fetch l_addendums_cur into l_addendum;
      
      l_first_month := trunc(l_agreement.effective_date, 'MM');
      l_months_cnt  := months_between(l_agreement.last_pay_date, l_first_month) + 1;
      l_amount      := 0;
      
      for m in l_months_cur(
        p_fk_contract    => l_agreement.fk_contract, 
        p_fk_credit      => l_agreement.fk_credit, 
        p_pay_code       => l_assignment_templ.fk_paycode,
        p_first_month    => l_first_month, 
        p_months_cnt     => l_months_cnt, 
        p_last_date      => l_agreement.last_pay_date
      ) loop  
        -- "прокрутить" курсор изменений до текущего мес€ца
        loop
          exit when l_addendums_cur%NOTFOUND or l_addendum.alt_date_begin >= m.paydate;
          
          l_amount := l_addendum.amount;
          fetch l_addendums_cur into l_addendum;
        end loop;
        
        l_month_pay := 0;
        l_day       := 1;
        l_day2      := extract(day from last_day(m.paydate));
        
        -- в текущем мес€це может оказатьс€ не одно, а несколько изменений
        loop
          exit when l_addendums_cur%NOTFOUND or l_addendum.alt_date_begin >= m.paydate;
          
          l_day_a := extract(day from l_addendum.alt_date_begin); 
          /*
          TODO: owner="V.Zhuravov" created="30.06.2018"
          text="переделать, возможно зацикливание"
          */
          if l_day_a <= l_day2 then
            l_month_pay := l_month_pay + (l_day_a - l_day) * l_amount;
            l_day       := l_day_a;
            l_amount    := l_addendum.amount;
            --fetch в if - привет бесконечный цикл
            fetch l_addendums_cur into l_addendum;
          end if;
          
        end loop;
        
        l_assignment_templ.fk_debit := nvl(l_addendum.fk_provacct, l_assignment_templ.fk_debit);

        -- даже если изменений нет совсем, формула ниже должна сработать
        l_month_pay := round((l_month_pay + (l_day2 - l_day + 1) * l_amount) / l_day2, 2);
        
        if m.paydate = l_first_month then
          l_day2 := l_day2 - extract(day from l_agreement.effective_date) + 1;
        end if;
        
        l_assignment := l_assignment_templ;
        
        l_assignment.paydate := m.paydate;
        l_assignment.paydays := l_day2;
        l_assignment.amount  := l_month_pay;
        
        assignments_api.push(
          p_assignment => l_assignment
        );
        
      end loop;
          
      close l_addendums_cur; 
      
    end loop;
    --
    close p_agreements_cur;
    --
    assignments_api.flush;
    --
  exception
    when others then
      if p_agreements_cur%isopen then
        close p_agreements_cur;
      end if;
      if l_addendums_cur%isopen then
        close l_addendums_cur;
      end if;
      --
      fix_exception($$PLSQL_LINE, 'fill_charges_life_contracts(' || p_pay_order.pay_order_id || ') failed');
      raise;
  end fill_charges_pension;
  
  /**
   *
   */
  function fill_charges_by_pay_order(
    p_pay_order_id number,
    p_oper_id   number
  ) return number is
  
    l_pay_order g_pay_order_typ;
    l_step           varchar2(255);
    --
    function is_exists_filter_(
      p_pay_oder_id number,
      p_filter_code varchar2
    ) return varchar2 is
      l_result varchar2(1);
    begin
      select 'Y'
      into   l_result
      from   pay_order_filters pof
      where  rownum = 1
      and    pof.fk_pay_order = p_pay_oder_id
      and    pof.filter_code = p_filter_code;
      
      return l_result;
    exception
      when no_data_found then
        return 'N';
    end;
    --
  begin
    --
    init_errors(
      p_log_mark  => GC_LM_ASSIGNMENTS,
      p_log_token => p_pay_order_id
    );
    --
    init;
    --
    l_step := '»нициализаци€ данных ордера: ' || p_pay_order_id;
    l_pay_order := get_pay_order(p_pay_order_id, p_oper_id);
    --
    if l_pay_order.fk_pay_order_type = 5 then
      if to_number(substr(l_pay_order.payment_freqmask, 7, 2)) > 0 then
        fill_charges_pension(
          p_pay_order       => l_pay_order,
          p_agreements_cur  => get_agreements_cur(
            p_pay_order       => l_pay_order,
            p_contract_type   => case to_number(substr(l_pay_order.payment_freqmask, 7, 2)) when 11 then null when 10 then GC_ASGPC_TERM when 1 then GC_ASGPC_LIFE end,
            p_filter_company  => is_exists_filter_(l_pay_order.pay_order_id, GC_POFLTR_COMPANY),
            p_filter_contract => is_exists_filter_(l_pay_order.pay_order_id, GC_POFLTR_CONTRACT)
          )
        );
      end if;
      
      /*if substr( vChargesMask,7,1 )='1' then
         Fill_Charges_TermContracts;
         end if;
      TM3:=Sysdate;
      -- единовременные выплаты
      if substr( vChargesMask,6,1 )='1' then
          Fill_Charges_LumpSumContracts;
          end if;
      */
    else
      log_write(3, 'Ќеобрабатываемый тип ордера: ' || l_pay_order.fk_pay_order_type);
      raise no_data_found;
    end if;
    --
    return GC_ST_SUCCESS;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'fill_charges_by_pay_order(' || p_pay_order_id || ', ' || p_oper_id || ') failed');
      
      Log_Write(3, 'ѕроцедура нормально не завершена из-за ошибки. ќткат транзакции.'  );
      Log_Write(3, l_step);
      Log_Write(3, get_error_msg);
      rollback;
      
      return GC_ST_ERROR;
      
  end fill_charges_by_pay_order;
  
end pay_gfnpo_pkg;
/
