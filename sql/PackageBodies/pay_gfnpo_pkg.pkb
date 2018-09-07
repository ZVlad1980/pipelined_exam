create or replace package body pay_gfnpo_pkg is
  
  GC_UNIT_NAME   constant varchar2(32) := $$PLSQL_UNIT;
  
  GC_ST_SUCCESS  constant number := 0;
  GC_ST_ERROR    constant number := 3;
  
  GC_DEPTH_RECALC constant number := 480; --период проверки начислений в месяцах (от декабря текущего года)
  
  GC_LM_ASSIGNMENTS  constant number := 1;
  
  GC_ASG_PAY_CODE        constant number := 5000;  -- начисление, код выплата пенсии
  
  GC_CT_TERM             constant varchar2(10) := 'TERM';
  GC_CT_LIFE             constant varchar2(10) := 'LIFE';
  GC_ASG_OP_TYPE         constant number := 2;      -- начисление, код типа для записей начисления пенсии
  
  GC_PO_TYPE_PEN         constant number := 5;      --платежка по пенсии
  GC_ACCT_TYPE_SSPV  constant number := 4;      -- тип солидарного счета
  
  GC_POFLTR_COMPANY  constant varchar2(10) := 'COMPANY';
  GC_POFLTR_CONTRACT constant varchar2(10) := 'CONTRACT';
  
  GC_CURTYP_INCLUDE  constant varchar2(10) := 'INCLUDE';
  GC_CURTYP_EXCLUDE  constant varchar2(10) := 'EXCLUDE';
  GC_CURTYP_NORMAL   constant varchar2(10) := 'NORMAL';
  
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
  
  procedure init_exception(
    p_log_mark  number,
    p_log_token number default null
  ) is
  begin 
    log_pkg.init_exception;
    G_LOG_MARK  := p_log_mark ;
    G_LOG_TOKEN := p_log_token;
  end init_exception;
  
  procedure put(
    p_message varchar2,
    p_eof     boolean default true
  ) is
  begin
    log_pkg.put(
      p_message => p_message,
      p_eof     => p_eof
    );
  end put;
  
  procedure fix_exception(
    p_line     number,
    p_message  varchar2,
    p_user_msg varchar2 default null
  ) is
  begin
    log_pkg.fix_exception(
      p_message   => p_message,
      p_unit_name => GC_UNIT_NAME,
      p_unit_line => p_line,
      p_user_msg  => p_user_msg
    );
    put('Error: ' || p_message);
  end fix_exception;
  
  function get_error_msg return varchar2 is
  begin
    return log_pkg.get_error_msg;
  end;
  
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
    
    put(p_msg);
    
  end log_write;
  
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
   * Функция возвращает процент пенс.соглашений, оплачиваемых в заданном периоде, от общего количества
   */
  function get_pct_period(
    p_period date
  ) return number is
    l_result number;
  begin
    select pap.pct
    into   l_result
    from   (
              select pap.payment_period,
                     pap.cnt,
                     round(pap.cnt / sum(pap.cnt)over(), 2) * 100 pct
              from   (
                        select /*+ materialize*/
                               trunc(pap.effective_date, 'MM') payment_period,
                               count(1) cnt
                        from   pension_agreement_periods pap
                        group by trunc(pap.effective_date, 'MM')
                     ) pap
           ) pap
    where pap.payment_period = p_period;
    return l_result;
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'get_pct_period(' || to_char(p_period, 'dd.mm.yyyy') || ')');
      raise;
  end get_pct_period;
  
  /**
   *
   */
  function get_max_depth(
    p_year number
  ) return number is
    l_min_period  date;
  begin
    select min(pap.effective_calc_date)
    into   l_min_period
    from   pension_agreement_periods_v pap;
    
    return months_between(to_date(p_year || '1201', 'yyyymmdd'), l_min_period) + 1;
    
  end get_max_depth;
  
  /**
   *
   */
  function get_assignments_cur(
    p_pay_order_id     pay_orders.fk_document%type,
    p_parallel         number,
    p_type_cur         varchar2,
    p_payment_period   date,
    p_contract_type    varchar2,
    p_filter_company   varchar2,
    p_filter_contract  varchar2
  ) return sys_refcursor is
  
    l_result        sys_refcursor;
    l_request       varchar2(32767);
    l_depth_recalc  number; --глубина поиска оплачиваемых периодов (от конца текущего года)
    
  begin
    l_depth_recalc := case p_type_cur --GC_CURTYP_INCLUDE/GC_CURTYPE_EXCLUDE/GC_CURTYP_NORMAL
      when GC_CURTYP_INCLUDE then 12 - months_between(p_payment_period, trunc(p_payment_period, 'Y'))
      else least(get_max_depth(extract(year from p_payment_period)), GC_DEPTH_RECALC)
    end;
    
    put('get_assignments_cur(' || p_type_cur || '): l_depth_recalc = ' || l_depth_recalc);
          
    l_request := 'with w_pay_order as ( --обрабатываемый pay_order
  select /*+ materialize*/
         po.fk_document,
         po.payment_period,
         po.start_month, 
         po.end_month, 
         po.start_quarter, 
         po.end_quarter, 
         po.start_halfyear,
         po.end_half_year, 
         po.start_year, 
         po.end_year,
         po.end_year_month
  from   pay_order_periods_v po
  where  po.fk_document = :fk_pay_order
),
w_months as ( --список обрабатываемых месяцев
  select /*+ materialize*/
         m.month_date,
         last_day(m.month_date) end_month_date
  from   w_pay_order po,
         lateral(
              select add_months(po.end_year_month, -1 * (level - 1)) month_date
              from   dual
              connect by level < :depth_recalc + 1
         ) m
)
select /*+ parallel(' || to_char(p_parallel) || ') */
       pa.fk_pension_agreement,
       coalesce(
         pa.fk_provacct,
         pa.fk_debit
       ) fk_debit,
       pa.fk_credit,
       pa.fk_company,
       pa.fk_scheme,
       pa.fk_contragent,
       pa.month_date paydate,
       pa.amount,
       trunc(least(pa.last_pay_date, pa.end_month_date)) - trunc(greatest(pa.month_date, pa.effective_date)) + 1 paydays,
       pa.last_pay_date,
       pa.addendum_from_date
from   (
        select pa.fk_pension_agreement,
               pa.fk_debit,
               pa.fk_credit,
               pa.fk_company,
               pa.fk_scheme,
               pa.fk_contragent,
               pa.effective_date,
               pa.expiration_date,
               m.month_date,
               m.end_month_date,
               paa.fk_provacct,
               case when m.month_date = paa.from_date then paa.first_amount else paa.amount end amount,
               least(pa.last_pay_date,
                 case pa.period_code 
                   when 1 then po.end_month
                   when 3 then po.end_quarter
                   when 6 then po.end_half_year
                   when 12 then po.end_year
                 end
               ) last_pay_date,
               period_code,
               paa.from_date addendum_from_date
        from   w_pay_order                   po,
               pension_agreement_periods_v   pa,
               w_months                      m,
               pension_agreement_addendums_v paa
        where  1 = 1
        and    m.month_date between paa.from_date and paa.end_date
        and    paa.fk_pension_agreement = pa.fk_pension_agreement
        and    not exists (
                 select 1
                 from   assignments a
                 where  1=1
                 and    a.fk_paycode = ' || GC_ASG_PAY_CODE || '
                 and    a.fk_doc_with_acct = pa.fk_pension_agreement
                 and    a.paydate between m.month_date and m.end_month_date 
                 and    a.fk_asgmt_type = ' || GC_ASG_OP_TYPE || '
               )
        and    not exists (
                  select 1
                  from   pay_restrictions pr
                  where  pr.fk_document_cancel is null
                  and    m.month_date between pr.effective_date and nvl(pr.expiration_date, m.month_date)
                  and    pr.fk_doc_with_acct = pa.fk_pension_agreement
               )
        and    m.month_date between pa.effective_calc_date and 
                 least(pa.last_pay_date, 
                   case pa.period_code 
                     when 1 then po.end_month
                     when 3 then po.end_quarter
                     when 6 then po.end_half_year
                     when 12 then po.end_year
                   end
                 )
        and    pa.effective_date <= po.end_month' || 
          case --если заданы фильтра
            when p_filter_contract = 'Y' then
              chr(10) ||
              'and pa.fk_pension_agreement in (
                 select pof.filter_value
                 from   pay_order_filters pof
                 where  pof.filter_code = :3
                 and    pof.fk_pay_order = po.fk_document)'
            when p_filter_company  = 'Y' then
              chr(10) ||
              'and pa.fk_company in (
                 select pof.filter_value
                 from   pay_order_filters pof
                 where  pof.filter_code = :3
                 and    pof.fk_pay_order = po.fk_document)'
          end || 
          case --если отдельно считаем пожизненные и срочные
            when p_contract_type = GC_CT_LIFE then
              chr(10) || 'and pa.expiration_date is null'
            when p_contract_type = GC_CT_TERM then
              chr(10) || 'and pa.expiration_date is not null'
          end ||
          case p_type_cur --если отдельно считаем текущий период
            when GC_CURTYP_INCLUDE then
              chr(10) || 'and pa.effective_calc_date = po.payment_period'
            when GC_CURTYP_EXCLUDE then --и все остальные
              chr(10) || 'and pa.effective_calc_date <> po.payment_period'
          end
       || chr(10) ||') pa'
    ;
    --
    put(l_request);
    --
    if p_filter_contract = 'Y' or p_filter_company = 'Y' then
      open l_result for l_request 
        using p_pay_order_id,
              l_depth_recalc,
              case when p_filter_contract = 'Y' then GC_POFLTR_CONTRACT when p_filter_company = 'Y' then GC_POFLTR_COMPANY end
       ;
    else
      open l_result for l_request 
        using p_pay_order_id,
              l_depth_recalc
      ;
    end if;
    
    return l_result;
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'get_assignments_cur(' || p_pay_order_id || ', ' || p_contract_type || ', ' || p_filter_company || ', ' || p_filter_contract || ') failed');
      raise;
  end get_assignments_cur;
  
  function get_assignments_calc(
    p_cursor sys_refcursor
  ) return assignments_tbl_typ
    pipelined
    parallel_enable(partition p_cursor by any)
  is
    l_rec        assignment_rec_typ;
  begin
    l_rec := assignment_rec_typ();
    loop
      fetch p_cursor 
        into l_rec.fk_contract  ,
             l_rec.fk_debit     ,
             l_rec.fk_credit    ,
             l_rec.fk_company   ,
             l_rec.fk_scheme    ,
             l_rec.fk_contragent,
             l_rec.paydate      ,
             l_rec.amount       ,
             l_rec.paydays      ,
             l_rec.last_pay_date,
             l_rec.addendum_from_date
        ;
      exit when p_cursor%notfound;
      if l_rec.fk_debit is null and l_rec.fk_scheme in (1, 5, 6) then
        l_rec.fk_debit := g_acct_sspv_tbl(l_rec.fk_scheme);
      end if;
      --если начисление за неполный последний месяц выплат
      if trunc(l_rec.paydate, 'MM') = trunc(l_rec.last_pay_date, 'MM') and
         last_day(l_rec.paydate) <> l_rec.last_pay_date          then
        --если в этом месяце были изменения пенсии
        if l_rec.addendum_from_date = trunc(l_rec.last_pay_date, 'MM') then
          /*
          TODO: owner="V.Zhuravov" created="06.09.2018"
          text="добавить перерасчет суммы начисления, для случая изменения суммы пенсии в последнем месяце выплат,
  с неполной оплатой"
          */
          log_write(log_pkg.C_LVL_WRN, 'Внимание! Пенс.договор ' || l_rec.fk_contract || ', дата завершения выплат: '
            || to_char(l_rec.last_pay_date, 'dd.mm.yyyy') || ', имеет изменения суммы в месяце завершения выплат!'
            || ' Расчет м.б. выполнен не верно, т.к. обработка такой ситуации не реализована (см. ' || GC_UNIT_NAME 
            || ', line ' || $$PLSQL_LINE || ')'
          );
        else
          l_rec.amount := round(l_rec.amount / to_number(extract(day from last_day(l_rec.paydate))) * l_rec.paydays, 2);
        end if;
      end if;
      
      pipe row(l_rec);
    end loop;
    
  end get_assignments_calc;
  
  /**
   *
   */
  procedure calc_assignments(
    p_pay_order          g_pay_order_typ,
    p_parallel           number,
    p_error_tag          varchar2,
    p_filter_company     varchar2,
    p_filter_contract    varchar2
  ) is
    
    procedure insert_assignments_(
      p_agreements_cur   sys_refcursor
    ) is
      l_start_time date;
    begin
      --put('Insert ASSIGNMENTS offline'); return;
      l_start_time := sysdate;
      put('start insert_assignments_ (at ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss') || ')... ', false);
      insert into assignments(
        id,
        fk_doc_with_action,
        fk_doc_with_acct,
        fk_debit,
        fk_credit,
        fk_asgmt_type,
        fk_contragent,
        paydate,
        amount,
        fk_paycode,
        paydays,
        fk_scheme,
        serv_doc
      ) select assignment_seq.nextval,
               p_pay_order.pay_order_id,
               t.fk_contract,
               t.fk_debit,
               t.fk_credit,
               GC_ASG_OP_TYPE,  -- код "начисление пенсии"
               t.fk_contragent,
               t.paydate,
               t.amount,
               GC_ASG_PAY_CODE, -- тип начисляемой пенсии (пожизненная/срочная)
               t.paydays,
               t.fk_scheme,
               t.fk_contract
        from   table(pay_gfnpo_pkg.get_assignments_calc(p_agreements_cur)) t
      log errors into err$_assignments (p_error_tag) reject limit unlimited;
      
      close p_agreements_cur;
      
      put('complete (at ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss') || '), duration: ' || to_char(round((sysdate - l_start_time) * 86400)) || ' sec');
      
    exception
      when others then
        
        if p_agreements_cur%isopen then
          close p_agreements_cur;
        end if;
        
        raise;
    end insert_assignments_;
  
  begin
    
    if p_filter_contract = 'N' and get_pct_period(p_pay_order.payment_period) > 80 then
      --если в текущем периоде более 80% соглашений - считаем его отдельно
      insert_assignments_(
        p_agreements_cur  => get_assignments_cur(
              p_pay_order_id    => p_pay_order.pay_order_id,
              p_parallel        => p_parallel,
              p_type_cur        => GC_CURTYP_INCLUDE,
              p_payment_period  => p_pay_order.payment_period,
              p_contract_type   => case to_number(substr(p_pay_order.payment_freqmask, 7, 2)) 
                                     when 11 then null 
                                     when 10 then GC_CT_TERM 
                                     when 1 then  GC_CT_LIFE end,
              p_filter_company  => p_filter_company ,
              p_filter_contract => p_filter_contract
            )
      );
      commit;
      insert_assignments_(
        p_agreements_cur  => get_assignments_cur(
              p_pay_order_id    => p_pay_order.pay_order_id,
              p_parallel        => p_parallel,
              p_type_cur        => GC_CURTYP_EXCLUDE,
              p_payment_period  => p_pay_order.payment_period,
              p_contract_type   => case to_number(substr(p_pay_order.payment_freqmask, 7, 2)) 
                                     when 11 then null 
                                     when 10 then GC_CT_TERM 
                                     when 1 then  GC_CT_LIFE end,
              p_filter_company  => p_filter_company ,
              p_filter_contract => p_filter_contract
            )
      );
    else
      --иначе считаем все периоды вместе
      insert_assignments_(
        p_agreements_cur  => get_assignments_cur(
              p_pay_order_id    => p_pay_order.pay_order_id,
              p_parallel        => p_parallel,
              p_type_cur        => GC_CURTYP_NORMAL,
              p_payment_period  => p_pay_order.payment_period,
              p_contract_type   => case to_number(substr(p_pay_order.payment_freqmask, 7, 2)) 
                                     when 11 then null 
                                     when 10 then GC_CT_TERM 
                                     when 1 then  GC_CT_LIFE end,
              p_filter_company  => p_filter_company ,
              p_filter_contract => p_filter_contract
            )
      );
    end if;
    
  exception
    when others then
      --
      fix_exception($$PLSQL_LINE, 'calc_assignments(' || p_pay_order.pay_order_id || ') failed');
      raise;
  end calc_assignments;
  
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
  procedure calc_assignments(
    p_pay_order_id number,
    p_oper_id      number,
    p_parallel     number default 4
  ) is
  
    l_pay_order g_pay_order_typ;
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
    init_exception(
      p_log_mark  => GC_LM_ASSIGNMENTS,
      p_log_token => p_pay_order_id
    );
    l_err_tag   := GC_UNIT_NAME || '_' || to_char(sysdate, 'yyyymmddhh24miss');
    --
    init;
    --
    l_pay_order := get_pay_order(p_pay_order_id, p_oper_id);
    --
    put('Update PA periods at ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
    update_pa_periods(
      l_pay_order.payment_period
    );
    put('Complete update PA periods at ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
    --
    if l_pay_order.fk_pay_order_type = 5 then
      if to_number(substr(l_pay_order.payment_freqmask, 7, 2)) > 0 then
        calc_assignments(
          p_pay_order       => l_pay_order,
          p_parallel        => p_parallel,
          p_error_tag       => l_err_tag,
          p_filter_company  => is_exists_filter_(l_pay_order.pay_order_id, GC_POFLTR_COMPANY),
          p_filter_contract => is_exists_filter_(l_pay_order.pay_order_id, GC_POFLTR_CONTRACT)
        );
      end if;
    else
      log_write(3, 'Необрабатываемый тип ордера: ' || l_pay_order.fk_pay_order_type);
      raise no_data_found;
    end if;
    --
    show_charges_results(l_pay_order.pay_order_id, l_err_tag);
    --
    commit;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'calc_assignments(' || p_pay_order_id || ', ' || p_oper_id || ') failed');
      rollback;
      raise;
  end calc_assignments;
  
  /**
   * Функция откатывает результаты начислений пенсий по заданному pPayOrder
   */
  procedure purge_assignments(
    p_pay_order_id number,
    p_oper_id      number,
    p_commit       boolean default true
  ) as
    l_pay_order g_pay_order_typ;
    
    --
    procedure update_pa_periods_ is
    begin
      merge into pension_agreement_periods pap
      using (select asg.fk_doc_with_acct fk_pension_agreement,
                    min(asg.paydate)     new_effective_date
             from   assignments asg
             where  asg.fk_doc_with_action = p_pay_order_id
             group by asg.fk_doc_with_acct
            )u
      on    (pap.fk_pension_agreement = u.fk_pension_agreement)
      when matched then
        update set
        pap.effective_date = least(u.new_effective_date, pap.effective_date)
      ;
    exception
      when others then
        fix_exception($$PLSQL_LINE, 'update_pa_periods_');
        raise;
    end update_pa_periods_;
    
    --
    procedure purge_assignments_ is
    begin
      delete from assignments asg
      where  asg.fk_doc_with_action = p_pay_order_id;
    exception
      when others then
        fix_exception($$PLSQL_LINE, 'purge_assignments_');
        raise;
    end purge_assignments_;
    --
  begin
    --
    init_exception(
      p_log_mark  => GC_LM_ASSIGNMENTS,
      p_log_token => p_pay_order_id
    );
    l_pay_order := get_pay_order(p_pay_order_id, p_oper_id);
    --
    if l_pay_order.fk_pay_order_type = GC_PO_TYPE_PEN then
      update_pa_periods_;
    end if;
    --
    purge_assignments_;
    --
    if p_commit then
      commit;
    end if;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'purge_assignments(' || p_pay_order_id || ', ' || p_oper_id || ') failed');
      rollback;
      
      raise;
    
  end purge_assignments;
  
  /**
   * Процедура обновляет список пенс.соглашений и их периоды оплат
   *  Возможен, и рекомендуем, ежедневный запуск по расписанию, для поддержания актуальности данных
   */
  procedure update_pa_periods(
    p_update_date   date,
    p_append_new    boolean default true
  ) is
    
    procedure append_new_ is
      l_new_rows number;
    begin
      merge into pension_agreement_periods pap
      using (select pac.fk_contract,
                    trunc(pac.effective_date, 'MM') effective_date,
                    pac.expiration_date             expiration_date
             from   pension_agreements_active_v pac
            ) u
      on    (pap.fk_pension_agreement = u.fk_contract)
      when not matched then
        insert(fk_pension_agreement, effective_date, expiration_date)
        values(u.fk_contract, u.effective_date, u.expiration_date)
      ;
      
      l_new_rows := sql%rowcount;
      
      commit;
      
      if l_new_rows > 10000 then
        dbms_stats.gather_table_stats(user, upper('pension_agreement_periods'), cascade => true);
      end if;
      
    exception
      when others then
        fix_exception($$PLSQL_LINE, 'append_new_ failed');
        raise;
    end append_new_;
    
    --
    --
    --
    procedure update_(p_update_date date) is
      l_end_year        date;
      l_next_year       date;
    begin
      l_end_year  := to_date(extract(year from p_update_date) || '1201', 'yyyymmdd');
      l_next_year := to_date(extract(year from p_update_date) + 1 || '0101', 'yyyymmdd');
      
      merge into pension_agreement_periods pap
      using (
              with w_months as ( --список обрабатываемых месяцев
                select /*+ materialize*/
                       m.month_date,
                       last_day(m.month_date) end_month_date
                from   lateral(
                            select add_months(l_end_year, -1 * (level - 1)) month_date
                            from   dual
                            connect by level < GC_DEPTH_RECALC + 1
                       ) m
              )
              select /*+ parallel(4)*/
                     pap.fk_pension_agreement,
                     pap.effective_date,
                     pap.first_restriction_date
              from   (
                select pap.fk_pension_agreement,
                       pap.effective_date curr_effective_date,
                       pap.first_restriction_date curr_restriction_date,
                       coalesce(pap2.effective_date, l_next_year) effective_date,
                       ( select min(pr.effective_date)
                         from   pay_restrictions pr
                         where  1=1--pr.effective_date <= coalesce(pap.expiration_date, pr.effective_date)
                         and    pr.fk_document_cancel is null
                         and    pr.fk_doc_with_acct = pap.fk_pension_agreement
                       ) first_restriction_date
                from   pension_agreement_periods pap
                left join
                       (
                          select pap.fk_pension_agreement,
                                 max(pap.effective_date) curr_effective_date,
                                 max(pap.first_restriction_date) curr_first_restriction_date,
                                 min(m.month_date) effective_date
                          from   pension_agreement_periods pap,
                                 w_months                  m
                          where  1=1
                          and    not exists ( --нет активного ограничения на этот месяц
                                   select 1
                                   from   pay_restrictions pr
                                   where  m.month_date between pr.effective_date and coalesce(pr.expiration_date, m.month_date)
                                   and    pr.effective_date <= coalesce(pap.expiration_date, pr.effective_date)
                                   and    pr.fk_document_cancel is null
                                   and    pr.fk_doc_with_acct = pap.fk_pension_agreement
                                 ) --*/
                          and    not exists(
                                   select 1
                                   from   assignments               asg
                                   where  asg.fk_paycode = GC_ASG_PAY_CODE
                                   and    asg.fk_asgmt_type = GC_ASG_OP_TYPE
                                   and    asg.paydate between m.month_date and m.end_month_date
                                   and    asg.fk_doc_with_acct = pap.fk_pension_agreement
                                 )
                          and    m.month_date >= least(pap.effective_date, coalesce(pap.first_restriction_date, pap.effective_date))
                          group by pap.fk_pension_agreement
                        ) pap2
                on pap2.fk_pension_agreement = pap.fk_pension_agreement
              ) pap
              where (
                    (coalesce(pap.curr_restriction_date, sysdate) <> coalesce(pap.first_restriction_date, sysdate))
                    or
                    (pap.curr_effective_date <> pap.effective_date)
              )
            ) u
      on    (pap.fk_pension_agreement = u.fk_pension_agreement)
      when matched then
        update set
          pap.effective_date = u.effective_date,
          pap.first_restriction_date = u.first_restriction_date
      ;
      commit;
    exception
      when others then
        fix_exception($$PLSQL_LINE, 'update_ failed');
        raise;
    end update_;
    
  begin
    
    if p_append_new then
      append_new_;
    end if;
    
    update_(trunc(p_update_date, 'MM'));
  
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'update_pa_periods(' || to_char(p_update_date, 'dd.mm.yyyy')|| ', ' || case when p_append_new then 'Append NEW' else 'Not append new' end || ') failed');
      raise;
  end update_pa_periods;
  

  /**
   * WRAP функция для процедуры calc_assignments (единообразие - поддержка сущ.API (см. PAY_GFOPS_PKG)
   * заполнить таблицу начислений пенсий
   */
  -- 
  function Fill_Charges_by_PayOrder( pPayOrder in number, pOperID in number ) RETURN NUMBER is
  begin
    
    calc_assignments(
      p_pay_order_id => pPayOrder,
      p_oper_id      => pOperID
    );
    
    return GC_ST_SUCCESS;
  exception
    when others then
      Log_Write(3, 'Процедура нормально не завершена из-за ошибки. Откат транзакции.'  );
      Log_Write(3, get_error_msg);
      return GC_ST_ERROR;
  end;
  
  /**
   * WRAP функция для purge_assignments - поддержка сущ.API (см. PAY_GFOPS_PKG)
   * очистка таблиц для отката операций по заданному распоряжению
   * удалить начисления
   */
  function Wipe_Charges_by_PayOrder( pPayOrder in number, pOperID in number, pDoNotCommit in number default 0 ) RETURN NUMBER is
  begin
    purge_assignments(
      p_pay_order_id => pPayOrder,
      p_oper_id      => pOperID,
      p_commit       => pDoNotCommit <> 0
    );
    return GC_ST_SUCCESS;
  exception
    when others then
      Log_Write(3, 'Wipe_Charges_by_PayOrder: Процедура нормально не завершена из-за ошибки. Откат транзакции.'  );
      Log_Write(3, get_error_msg);
      return GC_ST_ERROR;
  end;
  
end pay_gfnpo_pkg;
/
