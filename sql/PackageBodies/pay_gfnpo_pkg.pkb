create or replace package body pay_gfnpo_pkg is
  
  GC_UNIT_NAME   constant varchar2(32) := $$PLSQL_UNIT;
  
  GC_ST_SUCCESS  constant number := 0;
  GC_ST_ERROR    constant number := 3;
  
  GC_DEPTH_RECALC constant number := 180; --период проверки начислений в месяцах (от декабря текущего года)
  
  GC_LM_ASSIGNMENTS  constant number := 1;
  
  GC_ASG_PAY_CODE        constant number := 5000;  -- начисление, код выплата пенсии
  
  --Типы соглашений для начисления пенсий
  GC_CT_ALL              constant varchar2(10) := 'ALL';    --все
  GC_CT_PERIOD           constant varchar2(10) := 'PERIOD'; --срочные
  GC_CT_LIFE             constant varchar2(10) := 'LIFE';   --по жизненно
  
  GC_ASG_OP_TYPE         constant number := 2;      -- начисление, код типа для записей начисления пенсии
  
  GC_PO_TYPE_PEN         constant number := 5;      --платежка по пенсии
  
  GC_POFLTR_COMPANY  constant varchar2(10) := 'COMPANY';
  GC_POFLTR_CONTRACT constant varchar2(10) := 'CONTRACT';
  
  --типы пенс.схем
  GC_SCH_LIFE        constant varchar2(10) := 'LIFE';   --пожизненные выплаты
  GC_SCH_PERIOD      constant varchar2(10) := 'PERIOD'; --выплаты до определ.срока (применяется правило начисления остатка средств ИПС в последнюю выплату)
  GC_SCH_REST        constant varchar2(10) := 'REST';   --выплаты до исчерпания средств ИПС (применяется правило начисления остатка средств ИПС, если остаток меньше двух пенсий)
  
  --типы курсора для начислений (см. get_assignments_cur)
  GC_CURTYP_SIMPLE   constant varchar2(10) := 'SIMPLE';   --обработка начислений только за текущий оплачиваемый период (period_code=1)
  GC_CURTYP_COMPOUND constant varchar2(10) := 'COMPOUND'; --обработка прошлых периодов и периодичность > 1
  GC_CURTYP_ALL      constant varchar2(10) := 'ALL';      --все
  
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
  
  --Типы для кэширования спец. расчета пенсий
  type g_pension_rec_typ is record(
    amount   number,
    pay_days number
  );
  type g_pension_tbl_typ is table of g_pension_rec_typ index by varchar2(30);
  --коллекция для кеширования спец. расчета пенсий
  g_pension_tbl g_pension_tbl_typ;
  
  type g_num_varchar_hash_typ is table of varchar2(30) index by pls_integer;
  
  g_filters g_num_varchar_hash_typ;
  
  procedure init_exception(
    p_log_mark  number default G_LOG_MARK,
    p_log_token number default G_LOG_TOKEN
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
    
    put('log_write (' || case p_msg_level when log_pkg.C_LVL_ERR then 'ERROR' when log_pkg.C_LVL_WRN then 'WARNING' else 'INFO' end || '): ' || p_msg);
    
  end log_write;
  
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
  end get_pay_order;
  
  /**
   * Процедура чистит пакетный кэш 
   */
  procedure purge_hash_pkg is
  begin
    g_pension_tbl.delete;
    g_filters.delete;
  end purge_hash_pkg;
  
  /**
   */
  function get_index_pension_hash(
    p_fk_pension_agreement number, 
    p_month_date           date
  ) return varchar2 is
  begin
    return to_char(p_fk_pension_agreement) || '#' || to_char(p_month_date, 'yyyymmdd');
  end get_index_pension_hash;
    
  /**
   * 
   */
  procedure calc_pension_hash(
    p_ind_hash             varchar2,
    p_fk_pension_agreement number, 
    p_month_date           date
  ) 
  parallel_enable
  is
  begin
    put('calc_pension');
    with w_pension_agreement as (
      select p_fk_pension_agreement                                  fk_pension_agreement, 
             greatest(pa.effective_date, trunc(p_month_date, 'MM'))  month_date, 
             extract(day from least(coalesce(pa.expiration_date, last_day(p_month_date)), last_day(p_month_date))) month_days
      from   pension_agreements pa
      where  pa.fk_contract = p_fk_pension_agreement
    ),
    w_days as (
      select pa.fk_pension_agreement, 
             extract(day from last_day(pa.month_date)) cnt_days,
             d.day_date
      from   w_pension_agreement pa,
             lateral(
               select pa.month_date + (level - 1) day_date
               from   dual
               connect by level <= pa.month_days
             ) d
      where  d.day_date >= month_date
    )
    select round(sum(paa.amount / cnt_days), 2) amount,
           count(1) cnt
    into   g_pension_tbl(p_ind_hash).amount,
           g_pension_tbl(p_ind_hash).pay_days
    from   w_days             d,
           pa_addendums_det_v paa
    where  d.day_date between paa.from_date and coalesce(paa.end_date, d.day_date)
    and    not exists (
             select 1
             from   pay_restrictions pr
             where  d.day_date between pr.effective_date and coalesce(pr.expiration_date, d.day_date)
             and    pr.fk_doc_with_acct = d.fk_pension_agreement
           )
    and    paa.fk_pension_agreement = d.fk_pension_agreement
    group by d.fk_pension_agreement
    ;
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'calc_pension(' || p_ind_hash || ', ' || p_fk_pension_agreement || ', ' || to_char(p_month_date, 'dd.mm.yyyy') || ')');
      raise;
  end calc_pension_hash;
  
  /**
   * Функция расчета размера пенсии за заданный месяц
   *   Вызывается при начислении пенсии, если в месяце выплат есть дробные ограничения или дробное заверешние выплат
   */
  function get_pension(
    p_fk_pension_agreement number, 
    p_month_date           date
  ) return number
  deterministic
  parallel_enable
  is
    l_ind    varchar2(30);
  begin
    l_ind := get_index_pension_hash(p_fk_pension_agreement, p_month_date);
    if not g_pension_tbl.exists(l_ind) then
      calc_pension_hash(l_ind, p_fk_pension_agreement, p_month_date);
    end if;
    
    put('get_pension(' || p_fk_pension_agreement || ', ' || to_char(p_month_date, 'dd.mm.yyyy') || '): ' || g_pension_tbl(l_ind).amount);
    
    return g_pension_tbl(l_ind).amount;
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'get_pension(' || p_fk_pension_agreement || ', ' || to_char(p_month_date, 'dd.mm.yyyy') || ')');
      raise;
  end get_pension;
  
  /**
   * Функция расчета размера пенсии за заданный месяц
   *   Вызывается при начислении пенсии, если в месяце выплат есть дробные ограничения или дробное заверешние выплат
   */
  function get_pay_days(
    p_fk_pension_agreement number, 
    p_month_date           date
  ) return number
  deterministic
  parallel_enable
  is
    l_ind    varchar2(30);
  begin
    l_ind := get_index_pension_hash(p_fk_pension_agreement, p_month_date);
    if not g_pension_tbl.exists(l_ind) then
      calc_pension_hash(l_ind, p_fk_pension_agreement, p_month_date);
    end if;
    
    put('get_pay_days(' || p_fk_pension_agreement || ', ' || to_char(p_month_date, 'dd.mm.yyyy') || '): ' || g_pension_tbl(l_ind).pay_days);
    
    return g_pension_tbl(l_ind).pay_days;
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'get_pay_days(' || p_fk_pension_agreement || ', ' || to_char(p_month_date, 'dd.mm.yyyy') || ')');
      raise;
  end get_pay_days;
  
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
                               trunc(pap.calc_date, 'MM') payment_period,
                               count(1) cnt
                        from   pension_agreement_periods pap
                        group by trunc(pap.calc_date, 'MM')
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
    p_pay_order_id number
  ) return number is
    l_min_period  date;
    l_end_year    date;
  begin
    select min(pap.calc_date)
    into   l_min_period
    from   pension_agreement_periods_v pap;
    
    select to_date(to_char(extract(year from po.payment_period)) || '1231', 'yyyymmdd')
    into   l_end_year
    from   pay_orders po
    where  po.fk_document = p_pay_order_id;
    
    return round(months_between(l_end_year, l_min_period) + 1);
    
  end get_max_depth;
  
  function get_filter_code(
    p_pay_order_id     pay_orders.fk_document%type
  ) return varchar2 is
  begin
    
      if not g_filters.exists(p_pay_order_id) then
        select max(pof.filter_code)
        into   g_filters(p_pay_order_id)
        from   pay_order_filters pof
        where  pof.fk_pay_order = p_pay_order_id;
      end if;
      
      return g_filters(p_pay_order_id);
      
  end get_filter_code;
    
  /**
   * Функция get_assignments_cur возвращает открытый курсор 
   *   Для начислений по заданному периоду и ордеру
   *
   * @param p_pay_order_id  - 
   * @param p_type_cur      - тип курсора: GC_CURTYP_SIMPLE / GC_CURTYP_COMPOUND / GC_CURTYP_ALL (def)
   * @param p_parallel      - степень параллелизма
   * @param p_contract_type - тип обрабатываемых контрактов: GC_CT_ALL(def) / GC_CT_PERIOD / GC_CT_LIFE
   *
   */
  function get_assignments_cur(
    p_pay_order_id     pay_orders.fk_document%type,
    p_type_cur         varchar2 default null,
    p_contract_type    varchar2 default null,
    p_parallel         number   default 4
  ) return t_assignments_cur is
  
    l_result        t_assignments_cur;
    l_request       varchar2(32767);
    l_depth_recalc  number; --глубина поиска оплачиваемых периодов (от конца текущего года)
    l_months_query  varchar2(2000);
    l_pa_where      varchar2(2000);
    l_type_cur      varchar2(10);
    l_filter_code   varchar2(10);
    l_contract_type varchar2(10);
  begin  
    
    l_type_cur      := nvl(p_type_cur, GC_CURTYP_ALL);
    l_contract_type := nvl(p_contract_type, GC_CT_ALL);
    l_filter_code   := get_filter_code(p_pay_order_id);
    l_depth_recalc  := least(get_max_depth(p_pay_order_id), GC_DEPTH_RECALC);
    
    l_months_query := 'select /*+ materialize*/ ';
    
    if l_type_cur = GC_CURTYP_SIMPLE then
      l_pa_where := chr(10) ||
      'and  pa.calc_date = po.payment_period
       and  pa.period_code = 1';
      l_months_query := l_months_query || 'trunc(po.payment_period, ''MM'') month_date,
         last_day(po.payment_period) end_month_date
  from   w_pay_order po ';
--  where :depth_recalc > 0'; --просто чтобы не мудрить с параметрами
    else
      l_months_query := l_months_query || 'm.month_date,
         last_day(m.month_date) end_month_date
  from   w_pay_order po,
         lateral(
              select add_months(po.end_year_month, -1 * (level - 1)) month_date
              from   dual
              connect by level <= ' || l_depth_recalc || ' --:depth_recalc
         ) m';
      if l_type_cur = GC_CURTYP_COMPOUND then
        l_pa_where := chr(10) ||
      ' and  (pa.calc_date <> po.payment_period
              or pa.period_code <> 1)';
      else
        null;--l_pa_query := l_pa_query || chr(10) || ' where 1=1 ';
      end if;
    end if;
    
    l_pa_where := l_pa_where ||
      case --если заданы фильтра
        when l_filter_code = GC_POFLTR_CONTRACT then
          chr(10) ||
          'and pa.fk_pension_agreement in (
             select pof.filter_value
             from   pay_order_filters pof
             where  pof.filter_code = ''' || l_filter_code || '''
             and    pof.fk_pay_order = po.fk_document)'
        when l_filter_code  = GC_POFLTR_COMPANY then
          chr(10) ||
          'and pa.fk_company in (
             select pof.filter_value
             from   pay_order_filters pof
             where  pof.filter_code = ''' || l_filter_code || '''
             and    pof.fk_pay_order = po.fk_document)'
      end ||
      case --если отдельно считаем пожизненные и срочные
        when l_contract_type = GC_CT_LIFE then
          chr(10) || 'and pa.expiration_date is null'
        when l_contract_type = GC_CT_PERIOD then
          chr(10) || 'and pa.expiration_date is not null'
      end;
          
    l_request := 'with w_pay_order as ( --обрабатываемый pay_order
  select /*+ materialize*/
         po.fk_document,
         po.payment_period,
         po.operation_date,
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
  where  po.fk_document = ' || p_pay_order_id || ' --:fk_pay_order
),
w_months as ( --список обрабатываемых месяцев'
   || chr(10) || l_months_query || chr(10) || '
),
w_sspv as (
  select /*+ materialize*/
         acc.fk_scheme,
         acc.id fk_sspv_id
  from   accounts acc
  where  acc.fk_acct_type = 4
),
w_pension_agreements as (
  select /*+ materialize*/ 
     pa.fk_pension_agreement,
     pa.calc_date,
     pa.fk_base_contract,
     pa.state,
     pa.period_code,
     coalesce(ab.fk_account, sspv.fk_sspv_id, pa.fk_debit) fk_debit,
     pa.fk_credit,
     pa.fk_company,
     pa.fk_scheme,
     pa.fk_contragent,
     pa.effective_date,
     pa.expiration_date,
     pa.pa_amount,
     least(pa.last_pay_date,
           case pa.period_code 
             when 1 then  po.end_month
             when 3 then  po.end_quarter
             when 6 then  po.end_half_year
             when 12 then po.end_year
           end
     ) last_pay_date,
     pa.creation_date,
     po.payment_period,
     case when ab.fk_account is null and sspv.fk_sspv_id is not null then ''N'' else ''Y'' end is_ips,
     ab.amount account_balance,
     case 
       when pa.fk_scheme in (1, 5, 6) then
         ''' || GC_SCH_LIFE || '''
       when pa.fk_scheme in (2, 7) then
         ''' || GC_SCH_PERIOD || '''
       when pa.fk_scheme in (3, 4) then
         ''' || GC_SCH_REST || '''
       else
         ''UNKNOWN''
     end scheme_type
 from  pension_agreement_periods_v   pa,
       w_pay_order                   po,
       w_sspv                        sspv,
       accounts_balance              ab
 where coalesce(ab.transfer_date(+), po.payment_period) >= po.payment_period
 and   ab.fk_account(+) = pa.fk_debit
 and   sspv.fk_scheme(+) = pa.fk_scheme
 and    pa.effective_date <= po.end_month '
|| l_pa_where || chr(10) || ')' || chr(10) ||
'select /*+ parallel(' || to_char(p_parallel) || ') */
       pa.fk_pension_agreement,
       pa.fk_debit,
       pa.fk_credit,
       pa.fk_company,
       pa.fk_scheme,
       pa.fk_contragent,
       pa.paydate,
       pa.amount,
       pa.paydays,
       pa.addendum_from_date,
       pa.last_pay_date,
       pa.effective_date,
       pa.expiration_date,
       pa.account_balance,
       case pa.is_ips
         when ''Y'' then sum(pa.amount)over(partition by pa.fk_debit order by pa.paydate) 
       end total_amount,
       pa.pension_amount,
       pa.is_ips,
       pa.scheme_type
from   (
          select pa.fk_pension_agreement,
                 pa.fk_debit,
                 pa.fk_credit,
                 pa.fk_company,
                 pa.fk_scheme,
                 pa.fk_contragent,
                 pa.month_date paydate,
                 case
                   when pa.special_calc = ''Y'' then
                     pay_gfnpo_pkg.get_pension(pa.fk_pension_agreement, pa.month_date)
                   when pa.month_date = pa.addendum_from_date then 
                     pa.first_amount 
                   else pa.amount 
                 end amount,
                 case
                   when pa.special_calc = ''Y'' then
                     pay_gfnpo_pkg.get_pay_days(pa.fk_pension_agreement, pa.month_date)
                   else
                     trunc(least(pa.last_pay_date, pa.end_month_date)) - trunc(greatest(pa.month_date, pa.effective_date)) + 1
                 end paydays,
                 pa.addendum_from_date,
                 pa.last_pay_date,
                 pa.effective_date,
                 pa.expiration_date,
                 pa.account_balance,
                 pa.pension_amount,
                 pa.is_ips,
                 pa.scheme_type
          from   (
                  select pa.fk_pension_agreement,
                         pa.fk_debit,
                         pa.fk_credit,
                         pa.fk_company,
                         pa.fk_scheme,
                         pa.fk_contragent,
                         m.month_date,
                         m.end_month_date,
                         paa.first_amount ,
                         paa.amount ,
                         paa.from_date addendum_from_date,
                         pa.last_pay_date,
                         pa.effective_date,
                         pa.expiration_date,
                         pa.account_balance,
                         paa.amount pension_amount,
                         pa.is_ips,
                         pa.payment_period,
                         pa.period_code,
                         pa.scheme_type,
                         case 
                           when (pa.expiration_date between m.month_date and m.end_month_date - 1)
                             or exists(
                                  select 1
                                  from   pay_restrictions pr
                                  where  greatest(m.month_date, pa.effective_date) <= coalesce(pr.expiration_date, greatest(m.month_date, pa.effective_date))
                                  and    m.end_month_date >= pr.effective_date
                                  and    pr.fk_document_cancel is null
                                  and    pr.fk_doc_with_acct = pa.fk_pension_agreement
                                ) then ''Y''
                           else        ''N''
                         end special_calc
                  from   w_pension_agreements          pa,
                         w_months                      m,
                         pension_agreement_addendums_v paa
                  where  m.month_date between paa.from_date and paa.end_date
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
                            and    greatest(m.month_date, pa.effective_date) >= pr.effective_date 
                            and    m.end_month_date <= coalesce(pr.expiration_date, m.end_month_date)
                            and    pr.fk_doc_with_acct = pa.fk_pension_agreement
                         )
                  and    m.month_date between pa.calc_date and pa.last_pay_date'
                  || chr(10) || '    ) pa  ' --where not(pa.is_ips = ''Y'' and pa.account_balance <= 0)
                  || chr(10) || ') pa'     --pa.amount <> 0
    ;
    --
    put(rpad('-', 40, '-'));
    put('p_pay_order_id: ' || p_pay_order_id);
    put('l_depth_recalc: ' || l_depth_recalc);
    put('l_filter_code: ' || l_filter_code);
    put(rpad('-', 40, '-'));
    put(l_request);
    put(rpad('-', 40, '-'));
    --
    execute immediate 'declare l_result ' || GC_UNIT_NAME || '.t_assignments_cur; ' 
      || ' begin open l_result for ' || l_request || '; :1 := l_result; end;'
      using out l_result;
    
    /*open l_result for l_request 
      using p_pay_order_id,
            l_depth_recalc
    ;*/
    return l_result;
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'get_assignments_cur(' || p_pay_order_id || ', ' || p_contract_type || ') failed');
      raise;
  end get_assignments_cur;
  
  /**
   * Конвейерная функция для параллельного обхода курсора p_cursor 
   */
  function get_assignments_calc(
    p_cursor       t_assignments_cur,
    p_fk_pay_order number
  ) return t_assignments_tbl_typ
    pipelined
    parallel_enable(partition p_cursor by hash (fk_contract))
  is
    p_rec        t_assignments_rec_typ;
    l_message    varchar2(1024);
    
    --
    --
    --
    procedure log_write_(
      p_rec     in out nocopy t_assignments_rec_typ,
      p_msg_level varchar2,
      p_msg       varchar2 default null
    ) is
    begin
      
      log_write(
        p_msg_level => p_msg_level,
        p_msg       => p_msg 
                         || case when l_message is not null then 
                              case when  p_msg is not null then chr(10) end 
                              || l_message 
                            end
                         || '(контрагент: ' || p_rec.fk_contragent 
                         || ', дата начисления ' || to_char(p_rec.paydate, 'dd.mm.yyyy')
                         || ', сумма ' || to_char(p_rec.amount)
                         || case p_rec.is_ips when 'Y' then ', остаток ИПС: ' || to_char(p_rec.account_balance) end
                         || ', пенс.соглашение: ' || p_rec.fk_contract
                         || case p_rec.is_ips when 'Y' then ', ИПС: ' || p_rec.fk_debit end
                         || ')'
      );
    end log_write_;
    
    --
    --
    --
    function check_errors_(
      p_rec     in out nocopy t_assignments_rec_typ
    ) return boolean is
      l_result boolean;
      
    begin
      l_result := false;
      
      if p_rec.is_ips = 'Y' and nvl(p_rec.account_balance, 0) <= 0 then
        log_write_(p_rec, log_pkg.C_LVL_ERR, 'Нет денег на ИПС');
        l_result := true;
      end if;
      
      if nvl(p_rec.amount, 0) <= 0 then
        log_write_(p_rec, log_pkg.C_LVL_ERR, 'Не корректная сумма выплаты');
        l_result := true;
      end if;
      
      if p_rec.scheme_type = GC_SCH_REST and p_rec.expiration_date is not null then
        log_write_(p_rec, log_pkg.C_LVL_WRN, 'По схеме ' || p_rec.fk_scheme || ' задана дата завершения выплат: ' || to_char(p_rec.expiration_date, 'dd.mm.yyyy') );
      end if;
      
      return l_result;
      
    end check_errors_;
    
    --
    --
    --
    function check_rest_ips_(
      p_rec     in out nocopy t_assignments_rec_typ
    ) return boolean is
      l_result boolean;
    begin
      l_result := false;
      
      if (
           p_rec.total_amount > p_rec.account_balance
         )
        or
         (
           p_rec.scheme_type = GC_SCH_PERIOD                and
           trunc(p_rec.expiration_date, 'MM') = p_rec.paydate
         )
        or
         (
           p_rec.scheme_type = GC_SCH_REST                  and
           trunc(p_rec.last_pay_date, 'MM') = p_rec.paydate and
           (p_rec.account_balance - p_rec.total_amount) < p_rec.pension_amount
         )
      then
        p_rec.total_amount := p_rec.total_amount - p_rec.amount;
        p_rec.amount := p_rec.account_balance - p_rec.total_amount;
        p_rec.total_amount := p_rec.total_amount + p_rec.amount;
        
        if p_rec.amount <= 0 then
          log_write_(p_rec, log_pkg.C_LVL_ERR, 'Не достаточно средств на ИПС');
          l_result := true;
        else
          put('Выплачены остатки средств по ИПС' || ', пенс.соглашение: ' || p_rec.fk_contract);
        end if;
        
      end if;
      
      return l_result;
      
    end check_rest_ips_;
    
  begin
    
    init_exception(
      GC_LM_ASSIGNMENTS,
      p_fk_pay_order
    );
    
    loop
      
      fetch p_cursor 
        into p_rec;
      
      exit when p_cursor%notfound;
      
      continue when check_errors_(p_rec) or (p_rec.is_ips = 'Y' and check_rest_ips_(p_rec)); 

      pipe row(p_rec);
      
    end loop;
    
  end get_assignments_calc;
  
  /**
   *
   */
  procedure calc_assignments(
    p_pay_order          g_pay_order_typ,
    p_parallel           number,
    p_error_tag          varchar2/*,
    p_filter_company     varchar2,
    p_filter_contract    varchar2*/
  ) is
    
    l_contract_type varchar2(10);
    
    procedure insert_assignments_(
      p_agreements_cur   sys_refcursor
    ) is
      l_start_time date;
    begin
  --put('Insert ASSIGNMENTS offline'); close p_agreements_cur; return;
      
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
        from   table(pay_gfnpo_pkg.get_assignments_calc(p_agreements_cur, p_pay_order.pay_order_id)) t
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
    l_contract_type := case to_number(substr(p_pay_order.payment_freqmask, 7, 2)) 
      when 11 then GC_CT_ALL 
      when 10 then GC_CT_PERIOD 
      when 1 then  GC_CT_LIFE
    end;
    
    if get_filter_code(p_pay_order.pay_order_id) is null and get_pct_period(p_pay_order.payment_period) > 80 then
      --если в текущем периоде более 80% соглашений - считаем его отдельно
      insert_assignments_(
        p_agreements_cur  => get_assignments_cur(
              p_pay_order_id    => p_pay_order.pay_order_id,
              p_parallel        => p_parallel,
              p_type_cur        => GC_CURTYP_SIMPLE,
              p_contract_type   => l_contract_type
            )
      );
      commit;
      insert_assignments_(
        p_agreements_cur  => get_assignments_cur(
              p_pay_order_id    => p_pay_order.pay_order_id,
              p_parallel        => p_parallel,
              p_type_cur        => GC_CURTYP_COMPOUND,
              p_contract_type   => l_contract_type
            )
      );
    else
      --иначе считаем все периоды вместе
      insert_assignments_(
        p_agreements_cur  => get_assignments_cur(
              p_pay_order_id    => p_pay_order.pay_order_id,
              p_parallel        => p_parallel,
              p_type_cur        => GC_CURTYP_ALL,
              p_contract_type   => l_contract_type
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
   * Процедура начисления пенсий
   *
   *  begin
   *    log_pkg.enable_output;
   *    pay_gfnpo_pkg.calc_assignments(p_pay_order_id => 23890256, p_oper_id => 0);
   *  exception
   *    when others then
   *      log_pkg.show_errors_all;
   *  end;
   *
   */
  procedure calc_assignments(
    p_pay_order_id number,
    p_oper_id      number,
    p_parallel     number default 4
  ) is
  
    l_pay_order g_pay_order_typ;
    l_err_tag   varchar2(250);

  begin
    --
    init_exception(
      p_log_mark  => GC_LM_ASSIGNMENTS,
      p_log_token => p_pay_order_id
    );
    --очистка кеша спец.расчета пенсий
    purge_hash_pkg;
    --
    l_err_tag   := GC_UNIT_NAME || '_' || to_char(sysdate, 'yyyymmddhh24miss');
    --
    l_pay_order := get_pay_order(p_pay_order_id, p_oper_id);
    --
    --put('TEST MODE! ONLY BUILD QUERY');    /*
    put('Update PA periods at ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
    update_pa_periods(
      l_pay_order.operation_date
    );
    put('Complete update PA periods at ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
    --
    put('Update account balances at ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
    update_balances(
      l_pay_order.operation_date
    );
    put('Complete update balances at ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
    --*/
    if l_pay_order.fk_pay_order_type = 5 then
      if to_number(substr(l_pay_order.payment_freqmask, 7, 2)) > 0 then
        calc_assignments(
          p_pay_order       => l_pay_order,
          p_parallel        => p_parallel,
          p_error_tag       => l_err_tag
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
        pap.calc_date  = least(u.new_effective_date, pap.calc_date),
        pap.check_date = least(u.new_effective_date, pap.check_date)
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
    log_pkg.ClearByToken(
      pLogMark  => GC_LM_ASSIGNMENTS,
      pLogToken => p_pay_order_id
    );
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
      using (
             select pac.fk_contract,
                    trunc(pac.effective_date, 'MM') effective_date,
                    pac.effective_date              pa_effective_date
             from   pension_agreements_active_v pac
            ) u
      on    (pap.fk_pension_agreement = u.fk_contract)
      when not matched then
        insert(fk_pension_agreement, calc_date, check_date, pa_effective_date)
          values(u.fk_contract, u.effective_date, u.effective_date, u.pa_effective_date)
      ;
      
      l_new_rows := sql%rowcount;
      
      put('update_pa_periods: ' || l_new_rows || ' row(s) inserted');
      
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
    procedure update_(
      p_update_date  date
    ) is
      l_end_year        date;
      l_next_year       date;
    begin
      l_end_year  := to_date(extract(year from p_update_date) || '1201', 'yyyymmdd');
      l_next_year := to_date(extract(year from p_update_date) + 1 || '0101', 'yyyymmdd');
      
      update (
               select pap.calc_date,
                      pap.check_date,
                      pap.pa_effective_date,
                      trunc(pa.effective_date, 'MM') new_calc_date,
                      pa.effective_date              new_pa_effective_date
               from   pension_agreement_periods pap,
                      pension_agreements        pa
               where  1=1
               and    pap.pa_effective_date <> pa.effective_date
               and    pa.fk_contract = pap.fk_pension_agreement
             ) u
      set    u.calc_date         = u.new_calc_date,
             u.check_date        = u.new_calc_date,
      	     u.pa_effective_date = u.new_pa_effective_date
      ;
      
      merge into pension_agreement_periods pap
      using (
              with w_months as ( --список обрабатываемых месяцев
                select /*+ materialize*/
                       m.month_date,
                       last_day(m.month_date) end_month_date
                from   lateral(
                            select add_months(l_end_year, -1 * (level - 1)) month_date
                            from   dual
                            connect by level <= GC_DEPTH_RECALC
                       ) m
              )
              select /*+ parallel(4)*/
                     pap.fk_pension_agreement,
                     pap.new_calc_date          calc_date,
                     least(
                         coalesce(pap.new_check_date, pap.new_calc_date),
                         pap.new_calc_date
                     )                          check_date
              from   (
                select pap.fk_pension_agreement,
                       pap.calc_date                              curr_calc_date,
                       pap.check_date                             curr_check_date,
                       coalesce(pap2.new_calc_date, l_next_year)  new_calc_date,
                       trunc((select min(pr.effective_date)
                          from   pay_restrictions pr
                          where  1=1
                          and    pr.fk_document_cancel is null
                          and    pr.fk_doc_with_acct = pap.fk_pension_agreement
                         ), 'MM')                                 new_check_date
                from   pension_agreement_periods pap
                left join
                       (
                          select pap.fk_pension_agreement,
                                 min(m.month_date)     new_calc_date
                          from   pension_agreement_periods pap,
                                 w_months                  m
                          where  1=1
                          and    not exists ( --месяц не попадает целиком в период действий активного ограничения
                                   select 1
                                   from   pay_restrictions pr
                                   where  greatest(m.month_date, pap.pa_effective_date) >= pr.effective_date 
                                   and    m.end_month_date <= nvl(pr.expiration_date, m.end_month_date)
                                   and    pr.fk_document_cancel is null
                                   and    pr.fk_doc_with_acct = pap.fk_pension_agreement
                                 )
                          and    not exists(
                                   select 1
                                   from   assignments               asg
                                   where  asg.fk_paycode = GC_ASG_PAY_CODE
                                   and    asg.fk_asgmt_type = GC_ASG_OP_TYPE
                                   and    asg.paydate between m.month_date and m.end_month_date
                                   and    asg.fk_doc_with_acct = pap.fk_pension_agreement
                                 )
                          and    m.month_date >= pap.check_date
                          group by pap.fk_pension_agreement
                        ) pap2
                on pap2.fk_pension_agreement = pap.fk_pension_agreement
              ) pap
              where (
                      (pap.curr_check_date <> coalesce(pap.new_check_date,pap.new_calc_date))
                     or
                      (pap.curr_calc_date <> pap.new_calc_date)
                    )
            ) u
      on    (pap.fk_pension_agreement = u.fk_pension_agreement)
      when matched then
        update set
          pap.calc_date  = u.calc_date,
          pap.check_date = u.check_date
      ;
      
      put('update_pa_periods: ' || sql%rowcount || ' row(s) updated');
      
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
   * Процедура обновляет остатки по ИПС в таблице accounts_balance
   * 
   * p_update_date - дата, на которую рассчитываются остатки (временный параметр для тестирования)
   *
   */
  procedure update_balances(
    p_update_date date default sysdate
  ) is
    l_error_tag varchar2(100);
  begin
    l_error_tag := 'update_balances_' || to_char(p_update_date, 'yyyymmdd');
                   /* проверка даты перехода с ипс на сспв (на будущее, пока по FND)!
                   case --выражение на будущее, когда баланс будет по GF
                     when pa.fk_scheme = 5 then
                       (
                         select pp.transfer_date
                         from   pay_decisions  pd,
                                pay_portfolios pp
                         where  pp.id = pd.fk_pay_portfolio
                         and    pd.fk_pension_agreement = pa.fk_contract
                       )
                   end transfer_date,
                   */
    merge into accounts_balance b
    using ( with w_balances as (
              select /*+ materialize*/
                     tc.fk_contract             fk_base_contract,
                     ib.data_nach_vypl          effective_date,
                     ib.data_perevoda_5_cx      transfer_date,
                     sum(ib.amount)             amount
              from   fnd.sp_ips_balances    ib,
                     transform_contragents  tc
              where  ib.date_op < p_update_date
              and    tc.ssylka_fl = ib.ssylka
              group by tc.fk_contract, ib.data_nach_vypl, ib.data_perevoda_5_cx
            )
            select /*+ parallel(4)*/
                   pa.fk_debit,
                   b.transfer_date,
                   b.amount
            from   pension_agreements_active_v   pa,
                   w_balances                    b,
                   accounts_balance              ab
            where  1 = 1
            --
            and    ab.fk_account(+) = pa.fk_debit
            --
            and    b.effective_date(+) = pa.effective_date
            and    b.fk_base_contract(+) = pa.fk_base_contract
          ) u
    on    (b.fk_account = u.fk_debit)
    when not matched then
      insert (fk_account, transfer_date, amount, update_date)
        values(u.fk_debit, u.transfer_date, u.amount, sysdate)
    when matched then
      update set
        b.amount        = u.amount,
        b.transfer_date = u.transfer_date,
        b.update_date = sysdate
    log errors into err$_accounts_balance (l_error_tag) reject limit unlimited;
    
    put('update_balances: update ' || sql%rowcount || ' row(s)');
    
    commit;
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'update_balances(' || to_char(p_update_date, 'dd.mm.yyyy') || ') failed');
      rollback;
      raise;
  end update_balances;
  
end pay_gfnpo_pkg;
/
