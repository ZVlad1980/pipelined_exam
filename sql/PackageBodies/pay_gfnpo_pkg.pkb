create or replace package body pay_gfnpo_pkg is
  
  GC_UNIT_NAME   constant varchar2(32) := $$PLSQL_UNIT;
  
  GC_RM_DEBUG    constant varchar2(1) := 'D';
  --GC_RM_NORMAL   constant varchar2(1) := 'N';
  
  GC_RUN_MODE    constant varchar2(1)  := GC_RM_DEBUG;
  
  GC_ST_SUCCESS  constant number := 0;
  GC_ST_ERROR    constant number := 3;
  
  GC_BASE_DATE constant date := to_date(19950101, 'yyyymmdd'); --базовая дата начала выплат
  
  GC_LM_ASSIGNMENTS  constant number := 1;
  
  --GC_OPS_COMPANY         constant number := 1001;   -- вкладчик ОПС
  --GC_OPS_SCHEME          constant number := 7;      -- схема ОПС
  
  --GC_CONTRACT_PEN        constant number := 6;      -- контракт-пенсионное соглашение
  
  GC_ASG_PAY_CODE        constant number := 5000;  -- начисление, код выплата пенсии
  
  GC_CT_TERM             constant varchar2(10) := 'TERM';
  GC_CT_LIFE             constant varchar2(10) := 'LIFE';
  /*GC_ASGPC_LUMP          constant number := 5052;  -- начисление, код ЕДИНОВРЕМЕННАЯ ВЫПЛАТА
  GC_ASGPC_AUX           constant number := 5053;  -- начисление, код ДОПОЛНИТЕЛЬНАЯ ЕВ
  GC_ASGPC_ASSIGNEE      constant number := 5122;  -- начисление, код СУММА ПРАВОПРЕЕМНИКУ
  GC_ASGPC_WITHHOLDING   constant number := 7604;  -- начисление удержаний
  */
  GC_ASG_OP_TYPE         constant number := 2;      -- начисление, код типа для записей начисления пенсии
  
  --GC_PAST_NEW        constant number := 0;      -- статус соглашения на выплату - новое, готово к проверкам
  --GC_PAST_PAY        constant number := 1;      -- статус соглашения на выплату - фаза выплат (ПЛАТИТЬ)
  --GC_PAST_STOP       constant number := 2;      -- статус соглашения на выплату - обязательства выполнены (НЕ ПЛАТИТЬ)
  --GC_PAST_LIST       constant number := 6;      -- статус соглашения на выплату - проверено, подготовлено к выплате, включено в список на 1 выплату
  
  GC_ACCT_TYPE_SSPV  constant number := 4;      -- тип солидарного счета
  
  --GC_CNTRCT_ALL      constant varchar2(10) := 'ALL';  --
  --GC_CNTRCT_LIFE     constant varchar2(10) := 'LIVE'; --пожизненная пенсия
  --GC_CNTRCT_TERM     constant varchar2(10) := 'TERM'; --ежемесячные выплаты по срокам
  
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
    l_result.last_day_halfyear   := add_months(l_result.last_day_prev_year, 6 * l_result.charges_halfyear);  -- последний день полугодия ;
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
    l_sspv_schemes sys.odcinumberlist := 
      sys.odcinumberlist(1, 5, 6);
  begin
    log_write(log_pkg.C_LVL_INF, 'Определение счетов ССПВ для 1, 5 и 6 схем:');
    
    for i in 1..l_sspv_schemes.count loop
      begin
        select ac.id
        into   g_acct_sspv_tbl(l_sspv_schemes(i))
        from   accounts ac
        where  ac.fk_acct_type = GC_ACCT_TYPE_SSPV
        and    ac.fk_scheme = l_sspv_schemes(i);
      exception
        when others then
          fix_exception($$PLSQL_LINE, '  Ошибка: для схемы №' || l_sspv_schemes(i) || ' не найден ССПВ!');
          raise;
      end;
    end loop;
  end init;
  
  function add_month$(
    p_date   date,
    p_months int
  ) return date is
  begin
    return add_months(p_date, p_months);
  end add_month$;
  
  /**
   *
   */
  function get_agreements_cur(
    p_pay_order        g_pay_order_typ,
    p_contract_type    varchar2,
    p_filter_company   varchar2,
    p_filter_contract  varchar2,
    p_parallel     number
  ) return sys_refcursor is
    l_result  sys_refcursor;
    l_request varchar2(32767);
  begin
    
    l_request := 'with w_months as (
  select /*+ materialize*/ add_months(:0, level - 1) paydate
  from   dual
  connect by level < :1
)
select /*+ parallel(' || p_parallel || ') */ pa.fk_contract,
       pa.fk_base_contract,
       coalesce(paa.fk_provacct, pa.fk_debit) fk_debit,
       pa.fk_credit,
       pa.fk_company,
       pa.fk_scheme,
       pa.fk_contragent,
       pa.effective_date,
       pa.expiration_date,
       m.paydate,
       paa.amount charge_amount,
       last_day(least(pa.last_pay_date, :2)) last_pay_date
from   pension_agreements_charge_v   pa,
       w_months                      m,
       lateral(
         select paa.fk_provacct, case when m.paydate = paa.from_date then paa.first_amount else paa.amount end amount
         from   pension_agreement_addendums_v paa
         where  1=1
         and    m.paydate between paa.from_date and paa.end_date
         and    paa.fk_pension_agreement = pa.fk_contract
       ) paa
where  1 = 1
and    not exists (
         select 1
         from   assignments a
         where  trunc(a.paydate, ''MM'') = m.paydate
         and    a.fk_paycode = ' || GC_ASG_PAY_CODE || '
         and    a.fk_credit = pa.fk_credit
       )
and    not exists (
          select 1
          from   pay_restrictions pr
          where  pr.fk_document_cancel is null
          and    m.paydate between pr.effective_date and
                 nvl(pr.expiration_date, m.paydate)
          and    pr.fk_doc_with_acct = pa.fk_contract
       )
and    m.paydate between trunc(pa.effective_date, ''MM'') and trunc(least(pa.last_pay_date, :3), ''MM'')
and    pa.effective_date <= :4' || chr(10) ||
    case
      when p_filter_contract = 'Y' then
        'and pa.fk_contract in (
           select pof.filter_value
           from   pay_order_filters pof
           where  pof.filter_code = :5
           and    pof.fk_pay_order = :6)'
      when p_filter_company  = 'Y' then
        'and co.fk_company in (
           select pof.filter_value
           from   pay_order_filters pof
           where  pof.filter_code = :5
           and    pof.fk_pay_order = :6)'
    end || chr(10) || 
    case
      when p_contract_type = GC_CT_LIFE then
        'and pa.expiration_date is null'
      when p_contract_type = GC_CT_TERM then
        'and pa.expiration_date is not null'
    end
    /*end || chr(10) || 
    'order by case when pa.expiration_date is null then 1 else 2 end, pa.fk_company, pa.fk_scheme, pa.fk_contragent, m.paydate'
    */
    ;
    --
    put_line(l_request);
    
    if p_filter_contract = 'Y' or p_filter_company = 'Y' then
      open l_result for l_request 
        using GC_BASE_DATE,
              months_between(p_pay_order.payment_period, GC_BASE_DATE) + 2,
              p_pay_order.last_day_month, 
              p_pay_order.last_day_month,
              p_pay_order.last_day_month,
              case when p_filter_contract = 'Y' then GC_POFLTR_CONTRACT when p_filter_company = 'Y' then GC_POFLTR_COMPANY end,
              p_pay_order.pay_order_id;
    else
      open l_result for l_request 
        using GC_BASE_DATE,
              months_between(p_pay_order.payment_period, GC_BASE_DATE) + 2,
              p_pay_order.last_day_month, 
              p_pay_order.last_day_month,
              p_pay_order.last_day_month;
    end if;
    
    return l_result;
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'get_agreements_cur(' || p_pay_order.pay_order_id || ', ' || p_contract_type || ', ' || p_filter_company || ', ' || p_filter_contract || ') failed');
      raise;
  end get_agreements_cur;
  
  function get_solidary_acct_company(
    p_fk_company  contracts.fk_company%type,
    p_fk_scheme   contracts.fk_scheme%type
  ) return number RESULT_CACHE is
    
    l_result number;
  begin
    l_result := 10042;
    return l_result;
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'get_solidary_acct_company(' || p_fk_company || ', ' || p_fk_scheme || ') failed');
      raise;
  end get_solidary_acct_company;
  
  /**
   *
   */
  procedure fill_charges_pension(
    p_pay_order        g_pay_order_typ,
    p_agreements_cur   sys_refcursor,
    p_err_tag          varchar2
  ) is
    type l_agreements_typ is record (
      fk_contract           pension_agreements.fk_contract%type,
      fk_base_contract      pension_agreements.fk_base_contract%type,
      fk_debit              contracts.fk_account%type,
      fk_credit             contracts.fk_account%type,
      fk_company            contracts.fk_company%type,
      fk_scheme             contracts.fk_scheme%type,
      fk_contragent         contracts.fk_contragent%type,
      effective_date        pension_agreements.effective_date%type,
      expiration_date       pension_agreements.expiration_date%type,
      paydate               date,
      amount                number,
      last_pay_date         date
    );
    
    l_agreement l_agreements_typ;
    l_assignment  assignments%rowtype;
   
  begin
    --dbms_output.put_line('Процедура fill_charges_pension отключена');    return;
    assignments_api.init(p_err_tag => p_err_tag);
  
    l_assignment.fk_doc_with_action := p_pay_order.pay_order_id;
    l_assignment.fk_asgmt_type      := GC_ASG_OP_TYPE;  -- код "начисление пенсии"
    l_assignment.fk_paycode         := GC_ASG_PAY_CODE; ----case when l_agreement.expiration_date is null then GC_ASGPC_LIFE else GC_ASGPC_TERM end;  -- тип начисляемой пенсии (пожизненная/срочная)
      
    
    --for pa in l_agreements_cur(p_pay_order.pay_order_id, p_pay_order.last_day_month) loop
    loop
      fetch p_agreements_cur into l_agreement;
      exit when p_agreements_cur%notfound;
      
      l_assignment.fk_doc_with_acct := l_agreement.fk_contract;
      l_assignment.serv_doc         := l_agreement.fk_contract;
      l_assignment.fk_credit        := l_agreement.fk_credit;
      l_assignment.fk_scheme        := l_agreement.fk_scheme;
      l_assignment.fk_contragent    := l_agreement.fk_contragent;
      l_assignment.paydate          := l_agreement.paydate;
      l_assignment.paydays          := 
        least(last_day(l_agreement.paydate), l_agreement.last_pay_date) - 
        greatest(trunc(l_assignment.paydate, 'MM'), l_agreement.effective_date) + 1;
      l_assignment.amount           := l_agreement.amount;
      --l_assignment.comments         := 'Начисление пенсии. ОПС Пожизненная выплата.';
      
      l_assignment.fk_debit         := l_agreement.fk_debit;
      
      if l_assignment.fk_debit is null and l_assignment.fk_scheme in (1, 5, 6) then
        l_assignment.fk_debit := g_acct_sspv_tbl(l_assignment.fk_scheme);
      end if;
      
      assignments_api.push(
        p_assignment => l_assignment
      );
      
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
      --
      fix_exception($$PLSQL_LINE, 'fill_charges_pension(' || p_pay_order.pay_order_id || ') failed');
      raise;
  end fill_charges_pension;
  
  /**
   *
   */
  procedure show_charges_results(
    p_pay_order_id pay_orders.fk_document%type,
    p_err_tag      varchar2
  ) is
  
    procedure show_errors_ is
      cursor l_errs_cur is
        select a.ora_err_mesg$, fk_doc_with_acct
        from   err$_assignments a
        where  a.fk_doc_with_action = p_pay_order_id
        and    a.ora_err_tag$ = p_err_tag
        group by a.ora_err_mesg$, fk_doc_with_acct
        order by a.ora_err_mesg$, fk_doc_with_acct;
      l_ora_err_mesg$ err$_assignments.ora_err_mesg$%type;
    begin
      l_ora_err_mesg$ := '#ERROR#';
      for e in l_errs_cur loop
        if l_ora_err_mesg$ <> e.ora_err_mesg$ then
          l_ora_err_mesg$ := e.ora_err_mesg$;
          log_write(
            p_msg_level => log_pkg.C_LVL_ERR,
            p_msg       => 'Ошибка: ' || l_ora_err_mesg$
          );
        end if;
        log_write(
          p_msg_level => log_pkg.C_LVL_ERR,
          p_msg       => e.fk_doc_with_acct
        );
      end loop;
    exception
      when others then
        --
        fix_exception($$PLSQL_LINE, 'show_errors_(' || p_pay_order_id || ') failed');
        raise;
    end show_errors_;
    
  begin
    show_errors_;
  end show_charges_results;
  
  /**
   *
   */
  function fill_charges_by_pay_order(
    p_pay_order_id number,
    p_oper_id      number,
    p_parallel     number default 4
  ) return number is
  
    l_pay_order g_pay_order_typ;
    l_step      varchar2(255);
    l_err_tag   varchar2(250);
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
    
  begin
    --
    init_errors(
      p_log_mark  => GC_LM_ASSIGNMENTS,
      p_log_token => p_pay_order_id
    );
    l_err_tag   := GC_UNIT_NAME || '_' || to_char(sysdate, 'yyyymmddhh24miss');
    --
    init;
    --
    l_step := 'Инициализация данных ордера: ' || p_pay_order_id;
    l_pay_order := get_pay_order(p_pay_order_id, p_oper_id);
    --
    if l_pay_order.fk_pay_order_type = 5 then
      if to_number(substr(l_pay_order.payment_freqmask, 7, 2)) > 0 then
        fill_charges_pension(
          p_pay_order       => l_pay_order,
          p_agreements_cur  => get_agreements_cur(
            p_pay_order       => l_pay_order,
            p_contract_type   => case to_number(substr(l_pay_order.payment_freqmask, 7, 2)) 
                                   when 11 then null 
                                   when 10 then GC_CT_TERM 
                                   when 1 then  GC_CT_LIFE end,
            p_filter_company  => is_exists_filter_(l_pay_order.pay_order_id, GC_POFLTR_COMPANY),
            p_filter_contract => is_exists_filter_(l_pay_order.pay_order_id, GC_POFLTR_CONTRACT),
            p_parallel        => p_parallel
          ),
          p_err_tag           => l_err_tag
        );
      end if;
    else
      log_write(3, 'Необрабатываемый тип ордера: ' || l_pay_order.fk_pay_order_type);
      raise no_data_found;
    end if;
    --
    show_charges_results(l_pay_order.pay_order_id, l_err_tag);
    --
    return GC_ST_SUCCESS;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'fill_charges_by_pay_order(' || p_pay_order_id || ', ' || p_oper_id || ') failed');
      
      Log_Write(3, 'Процедура нормально не завершена из-за ошибки. Откат транзакции.'  );
      Log_Write(3, l_step);
      Log_Write(3, get_error_msg);
      rollback;
      
      return GC_ST_ERROR;
      
  end fill_charges_by_pay_order;
  
end pay_gfnpo_pkg;
/
