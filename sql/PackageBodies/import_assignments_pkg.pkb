create or replace package body import_assignments_pkg is

  GC_UNIT_NAME   constant varchar2(32) := $$PLSQL_UNIT;
  
  GC_ACCTYP_LSPV constant number := 114; --LSPV
  GC_ACCTYP_IPS  constant number := 23; --IPS
  
  GC_ACT_OPEN_ACC  constant number := 50; --открытие счета
  GC_ACT_CLOSE_ACC constant number := 60; --закрытие счета
  
  GC_PAYMENT_FREQMASK constant pay_orders.payment_freqmask%type := '00001111';
  GC_PO_TYP_PENS      constant number                           := 5;
  
  GC_PAY_CODE_PENSION constant assignments.fk_paycode%type := 5000;
  
  GC_PR_DOC_CANCEL    constant number                      := 0;
  GC_PR_DOC_INIT      constant number                      := 0;
  
  procedure init_exception is
  begin 
    log_pkg.init_exception;
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
  
  function is_exists_error(
    p_err_table varchar2,
    p_err_tag   varchar2
  ) return boolean is
    l_dummy int;
  begin
    execute immediate 'select 1 from ' || p_err_table || ' where rownum = 1 and ora_err_tag$ = :1' into l_dummy using p_err_tag;
    return true;
  exception
    when no_data_found then
      return false;
  end is_exists_error;
  
  
  function get_sspv_id(
    p_fk_scheme accounts.fk_scheme%type
  ) return accounts.id%type 
    result_cache
  is
    l_result accounts.id%type;
  begin
    select a.id
    into   l_result
    from   accounts_sspv_v a
    where  a.fk_scheme = p_fk_scheme;

    return l_result;
           
  exception
    when no_data_found then
      return null;
    when others then
      fix_exception($$PLSQL_LINE, 'get_sspv_id(' || p_fk_scheme || ')');
      raise;
  end get_sspv_id;
  
  /**
   */
  
  procedure gather_table_stats(
    p_table_name varchar2
  ) is
    l_time number;
  begin
    /*
    put('gather_table_stats(' || p_table_name || '): сбор статистики отключен!');
    return;
    */
    l_time := dbms_utility.get_time;
    put('Start gather stats for ' || p_table_name || ' ... ', false);
    dbms_stats.gather_table_stats(user, p_table_name);
    put('Ok, duration: ' || to_char(dbms_utility.get_time - l_time) || ' ms');
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'gather_table_stats(' || p_table_name || ')');
      init_exception;
  end gather_table_stats;
  
  /**
   * Процедура заполняет таблицу TRANSFORM_PA, данными из FND
   */
  procedure insert_transform_pa(
    p_from_date date,
    p_to_date   date
  ) is
  begin
    merge into transform_pa pa
    using (select tc.fk_contract,
                  tc.fk_contragent,
                  pd.ssylka, 
                  pd.data_nach_vypl, 
                  pd.ref_kodinsz,
                  pd.source_table,
                  pd.data_arh
           from   fnd.sp_pen_dog_imp_v  pd,
                  transform_contragents tc
           where  1=1
           and    not exists (
                     select 1
                     from   pension_agreements_v    pa
                     where  1 = 1
                     and    pa.effective_date = pd.data_nach_vypl
                     and    pa.fk_base_contract = tc.fk_contract
                   )
           and    tc.ssylka_fl(+) = pd.ssylka
           and    exists (
                     select 1
                     from   fnd.vypl_pen vp
                     where  1 = 1
                     and    vp.data_nachisl between pd.from_date and pd.to_date
                     and    vp.ssylka_fl = pd.ssylka
                     and    vp.data_op between p_from_date and p_to_date
                  )
          ) u
    on    (pa.ssylka_fl = u.ssylka and pa.date_nach_vypl = u.data_nach_vypl)
    when matched then
      update set
        fk_base_contract = u.fk_contract,
        fk_contragent    = u.fk_contragent,
        fk_contract      = null
    when not matched then
      insert(
        ssylka_fl,
        date_nach_vypl,
        fk_base_contract,
        fk_contragent,
        ref_kodinsz,
        source_table,
        data_arh
      ) values (
        u.ssylka, 
        u.data_nach_vypl, 
        u.fk_contract,
        u.fk_contragent,
        u.ref_kodinsz,
        u.source_table,
        u.data_arh
      )
    ;
    put('insert_transform_pa: добавлено строк: ' || sql%rowcount);
    
    update transform_pa tpa
    set    tpa.ref_kodinsz = document_seq.nextval
    where  tpa.ref_kodinsz is null
    and    tpa.fk_contract is null;
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'insert_transform_pa(' || to_char(p_from_date, 'dd.mm.yyyy') || ',' || to_char(p_from_date, 'dd.mm.yyyy') || ')');
      raise;
  end insert_transform_pa;
  
  /**
   * Процедура создает пенс.соглашения по необработанным записям TRANSFORM_PA (fk_contract is null)
   */
  procedure create_pension_agreements(
    p_err_tag varchar2
  ) is
    C_FK_CONTRACT_TYPE constant number := 6;
    C_FK_WORKPLACE     constant number := null;
  begin
    
    insert all
      when doc_exists = 'N' and ref_kodinsz is not null then
        into documents(id, fk_doc_type, doc_date, title, fk_doc_with_acct, is_accounting_doc)
        values(ref_kodinsz, 2, cntr_date, doctitle, ref_kodinsz, 0)
        log errors into ERR$_IMP_DOCUMENTS (p_err_tag) reject limit unlimited
      when cntr_exists = 'N' then
        into contracts(fk_document, cntr_number, cntr_index, cntr_date, title, fk_cntr_type, fk_workplace, fk_contragent,  fk_company, fk_scheme, fk_closed)
        values(ref_kodinsz, cntr_number, cntr_index,cntr_date, doctitle, C_FK_CONTRACT_TYPE, C_FK_WORKPLACE, fk_contragent, fk_company, fk_scheme, null)
        log errors into ERR$_IMP_CONTRACTS (p_err_tag) reject limit unlimited
      when 1 = 1 then
        into pension_agreements(fk_contract, effective_date, expiration_date, amount, delta_pen, fk_base_contract, period_code, years, state, isarhv, creation_date, last_update)
        values (ref_kodinsz, date_nach_vypl, data_okon_vypl, razm_pen, delta_pen, coalesce(fk_base_contract, -1), period_code, years, state, isarhv, pd_creation_date, sysdate)
        log errors into ERR$_IMP_PENSION_AGREEMENTS (p_err_tag) reject limit unlimited
    select t.doc_exists,
           t.cntr_exists,
           t.fk_base_contract,
           t.ref_kodinsz,
           t.cntr_date,
           t.cntr_number,
           t.cntr_index,
           t.doctitle,
           t.fk_contragent,
           t.fk_company,
           t.fk_scheme,
           t.date_nach_vypl,
           t.data_okon_vypl,
           t.razm_pen,
           t.delta_pen,
           t.period_code,
           t.years,
           t.state,
           t.isarhv,
           t.pd_creation_date
    from   (
    select tpa.ssylka_fl       ,
           tpa.date_nach_vypl  ,
           tpa.fk_base_contract,
           tpa.fk_contragent   ,
           tpa.ref_kodinsz     ,
           tpa.fk_contract     ,
           tpa.source_table    ,
           case
             when exists(
                    select 1
                    from   documents d2
                    where  d2.id = tpa.ref_kodinsz
                  )
               then 'Y' 
             else   'N' 
           end                  doc_exists,
           case
             when exists(
                    select 1
                    from   contracts cn2
                    where  cn2.fk_document = tpa.ref_kodinsz
                  )
               then 'Y' 
             else   'N' 
           end                  cntr_exists,
           --
           tpa.ssylka_fl cntr_number,
           lpad(row_number()over(partition by tpa.ssylka_fl order by tpa.ssylka_fl, tpa.date_nach_vypl) + (select coalesce(count(1), 0) from contracts cn2 where cn2.cntr_number = tpa.ssylka_fl and cn2.fk_cntr_type = 6), 2, '0') cntr_index,
           pd.cntr_print_date,
           pd.data_arh             cntr_close_date,
           tpa.ref_kodinsz         fk_document,
           'Пенсионное соглашение: '||trim(to_char(pd.nom_vkl, '0000'))||'/'||trim(to_char(pd.ssylka, '0000000')) as doctitle,
           pd.cntr_date,
           6 cntr_type,
           pd.nom_vkl fk_company,
           pd.shema_dog fk_scheme,
           pd.data_nach_vypl,
           pd.pd_data_okon_vypl data_okon_vypl,
           pd.razm_pen,
           pd.delta_pen,
           nvl(pd.id_period_payment, 0) period_code,
           case 
             when pd.id_period_payment <> 0 and pd.data_okon_vypl is not null then extract(year from pd.data_okon_vypl) - extract(year from pd.data_nach_vypl)
             else null
           end                                  years,
           case
             when pd.source_table = 'SP_PEN_DOG_ARH' then
               2
             when lspv.status_pen in ('п', 'и') then 1
             when lspv.status_pen = 'о' then 2
             else 0 
           end as                               state,
           case when pd.source_table = 'SP_PEN_DOG_ARH' then 1 else 0 end isarhv,
             pd.data pd_creation_date
    from   transform_pa      tpa,
           fnd.sp_pen_dog_v  pd,
           fnd.sp_lspv       lspv
    where  1=1--rownum < 50 --=1
    and    lspv.ssylka_fl = pd.ssylka
    and    pd.data_nach_vypl = tpa.date_nach_vypl
    and    pd.ssylka = tpa.ssylka_fl
    and    not exists (
             select 1
             from   pension_agreements pa
             where  pa.fk_contract = tpa.ref_kodinsz
             and    pa.effective_date = tpa.date_nach_vypl
           )
    and    tpa.fk_contract is null
    and    tpa.ref_kodinsz is not null
    order by tpa.ssylka_fl,
           tpa.date_nach_vypl
    ) t;
    
    update transform_pa tpa
    set    tpa.fk_contract = tpa.ref_kodinsz
    where  1=1
    and    exists(
             select 1
             from   pension_agreements_v pa
             where  pa.effective_date = tpa.date_nach_vypl
             and    pa.fk_contract = tpa.ref_kodinsz
           )
    and    tpa.fk_contract is null;
    
    update (select pda.ref_kodinsz,
                   tpa.fk_contract
            from   transform_pa       tpa,
                   fnd.sp_pen_dog_arh pda
            where  1=1
            and    pda.ref_kodinsz is null
            and    pda.data_arh = tpa.data_arh
            and    pda.ssylka = tpa.ssylka_fl
            and    tpa.source_table = 'SP_PEN_DOG_ARH'
            and    tpa.fk_contract is not null
           ) u
    set    u.ref_kodinsz = u.fk_contract;
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_pension_agreements');
      raise;
  end create_pension_agreements;
  
  /**
   * Процедура заполняет таблицу TRANSFORM_PA, данными из FND
   */
  procedure insert_transform_pa_portfolio is
  begin
    merge into transform_pa_portfolios pap
    using (select t.ssylka_fl,
                  t.date_nach_vypl,
                  t.source_table,
                  t.pd_creation_date,
                  t.change_date,
                  t.kod_izm,
                  t.kod_doc,
                  t.nom_izm,
                  t.true_kod_izm --*/
           from   (
                    select tpa.ssylka_fl,
                           tpa.date_nach_vypl,
                           tpa.source_table,
                           trunc(pd.data) pd_creation_date,
                           trunc(iz.data_zanes) change_date,
                           iz.kod_izm,
                           iz.kod_doc,
                           iz.nom_izm,
                           case 
                             when iz.kod_izm in (12, 24, 66, 68, 81, 85, 87, 88, 89, 90, 92, 107, 109, 72, 73) then 'Y'
                             else 'N'
                           end true_kod_izm,
                           row_number() over (partition by tpa.ssylka_fl, tpa.date_nach_vypl
                             order by case when iz.kod_izm in (12, 24, 66, 68, 81, 85, 87, 88, 89, 90, 92, 107, 109, 72, 73) then 0 --прямой код изменения
                               else 1000 --обходной код
                               end + to_number(abs(iz.data_zanes - pd.data)) + (iz.kod_izm / 100)
                             ) rn
                    from   transform_pa         tpa,
                           fnd.sp_pen_dog_imp_v pd,
                           fnd.izmeneniya_pd_v  iz
                    where  1=1
                    and    (
                             (iz.kod_izm in (12, 24, 66, 68, 81, 85, 87, 88, 89, 90, 92, 107, 109, 72, 73)
                             )
                            or
                             (
                              exists (
                                select 1
                                from   fnd.izmeneniya       iz2
                                where  iz2.kod_doc = iz.kod_doc
                                and    iz2.kod_izm in (12, 24, 66, 68, 81, 85, 87, 88, 89, 90, 92, 107, 109, 72, 73)
                              )
                             )
                           )
                    and    abs(iz.data_zanes - pd.data) < 10
                    and    iz.ssylka_fl_str = to_char(pd.ssylka)
                    and    pd.data_nach_vypl = tpa.date_nach_vypl
                    and    pd.ssylka = tpa.ssylka_fl
                    and    not exists (
                             select 1
                             from   pay_decisions pdd
                             where  pdd.fk_pension_agreement = tpa.fk_contract                          
                           )
                    and    tpa.fk_contract is not null
                  ) t
           where t.rn = 1
          ) u
    on    (pap.ssylka_fl = u.ssylka_fl and pap.date_nach_vypl = u.date_nach_vypl)
    when matched then
      update set
        fk_pay_portfolio = null,
        fk_pay_decision  = null
    when not matched then
      insert(
        ssylka_fl,
        date_nach_vypl,
        source_table,
        pd_creation_date,
        change_date,
        kod_izm,
        kod_doc,
        nom_izm,
        true_kod_izm
      ) values (
        u.ssylka_fl,
        u.date_nach_vypl,
        u.source_table,
        u.pd_creation_date,
        u.change_date,
        u.kod_izm,
        u.kod_doc,
        u.nom_izm,
        u.true_kod_izm
      )
    ;
    put('insert_transform_pa_portfolios: добавлено строк: ' || sql%rowcount);
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'insert_transform_pa_portfolio');
      raise;
  end insert_transform_pa_portfolio;
  
  /**
   * Процедура создает доп.документы для групповых назначений
   */
  procedure create_portfolio_docs(
    p_err_tag varchar2
  ) is
  begin
    update transform_pa_portfolios tpp
    set    tpp.fk_document = document_seq.nextval
    where  (tpp.ssylka_fl, tpp.date_nach_vypl) in (
            select tpp.ssylka_fl,
                   tpp.date_nach_vypl
            from   (
                    select tpp.ssylka_fl,
                           tpp.date_nach_vypl,
                           tpp.kod_doc,
                           row_number()over(partition by tpp.kod_doc order by tpp.ssylka_fl, tpp.date_nach_vypl) rn,
                           case 
                             when pp.id is null then 'N'
                             else 'Y'
                           end is_exists
                    from   transform_pa_portfolios tpp,
                           pay_portfolios          pp
                    where  1=1
                    and    pp.fk_doc_application(+) = tpp.kod_doc
                    and    tpp.fk_document is null
                   ) tpp
            where  1=1
            and    not (tpp.rn = 1 and tpp.is_exists = 'N')
           );
    --
    put('create_portfolio_docs: выделено новых номеров документов: ' || sql%rowcount);
    --
    update transform_pa_portfolios tpp
    set    tpp.fk_document = tpp.kod_doc
    where  tpp.fk_document is null;
    --
    insert into documents(
      id,
      fk_doc_type,
      doc_date,
      fk_file,
      title,
      parent_id,
      reg_dept_num,
      reg_act_num,
      reg_doc_num,
      barcode,
      abstract,
      resolution,
      fk_printed,
      fk_signed,
      fk_deleted,
      fk_hold,
      fk_done,
      fk_treenode,
      fk_registration_card,
      fk_doc_out,
      fk_doc_with_acct,
      fk_doc_with_cash,
      fk_doc_linked,
      in_doc_number,
      in_doc_date,
      fk_operator,
      motiw_id,
      motiw_doc,
      creation_date,
      change_date,
      isdelete,
      last_update,
      priority,
      is_accounting_doc,
      fk_scan,
      fk_npf_origin,
      fk_email,
      fk_orig_barcode_scaned
    ) select tpp.fk_document,
             d.fk_doc_type,
             d.doc_date,
             d.fk_file,
             d.title,
             d.parent_id,
             d.reg_dept_num,
             d.reg_act_num,
             d.reg_doc_num,
             d.barcode,
             d.abstract,
             d.resolution,
             d.fk_printed,
             d.fk_signed,
             d.fk_deleted,
             d.fk_hold,
             d.fk_done,
             d.fk_treenode,
             d.fk_registration_card,
             d.fk_doc_out,
             d.fk_doc_with_acct,
             d.fk_doc_with_cash,
             d.fk_doc_linked,
             d.in_doc_number,
             d.in_doc_date,
             d.fk_operator,
             d.motiw_id,
             d.motiw_doc,
             d.creation_date,
             d.change_date,
             d.isdelete,
             d.last_update,
             d.priority,
             d.is_accounting_doc,
             d.fk_scan,
             d.fk_npf_origin,
             d.fk_email,
             d.fk_orig_barcode_scaned
      from   transform_pa_portfolios tpp,
             documents               d
      where  1=1
      and    d.id = tpp.kod_doc
      and    not exists (select 1 from documents d where d.id = tpp.fk_document)
      and    tpp.fk_document <> tpp.kod_doc
      and    tpp.fk_pay_portfolio is null
    log errors into ERR$_IMP_DOCUMENTS (p_err_tag) reject limit unlimited;
    
    put('create_portfolio_docs: created ' || sql%rowcount || ' document(s)');
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_portfolio_docs');
      raise;
  end create_portfolio_docs;
  
  /**
   * Процедура создает PAY_PORTFOLIOS
   */
  procedure create_portfolios(
    p_err_tag varchar2
  ) is
    l_creation_date date;
  begin
    l_creation_date := sysdate;
    insert into pay_portfolios(
      fk_doc_application,
      fk_app_type,
      date_request,
      fk_pay_detail,
      creation_date,
      fk_operator,
      fk_contract,
      info_pfr_valid,
      amount,
      fk_scheme,
      fk_pfr_pension_type,
      date_not_consider,
      order_paper_required,
      labor_book_required
    ) select tpp.fk_document,
             2,
             d.doc_date,
             pa.fk_pay_detail,
             l_creation_date,
             53,
             tpa.fk_base_contract,
             1,
             0,
             pa.fk_scheme,
             0,
             null,
             0,
             0
      from   transform_pa_portfolios tpp,
             transform_pa            tpa,
             pension_agreements_v    pa,
             documents               d
      where  1=1
      and    d.id = tpp.fk_document
      and    pa.fk_contract = tpa.fk_contract
      and    tpa.date_nach_vypl = tpp.date_nach_vypl
      and    tpa.ssylka_fl = tpp.ssylka_fl
      and    tpp.true_kod_izm in ('Y', 'N')
      and    tpp.fk_pay_portfolio is null
    log errors into ERR$_IMP_PAY_PORTFOLIOS (p_err_tag) reject limit unlimited;
    
    put('create_portfolios: inserted ' || sql%rowcount || ' row(s)');
    
    update transform_pa_portfolios tpp
    set    tpp.fk_pay_portfolio = (
             select pp.id
             from   transform_pa           tpa,
                    pay_portfolios         pp
             where  1=1
             and    pp.creation_date = l_creation_date
             and    pp.fk_doc_application = tpp.fk_document
             and    pp.fk_contract = tpa.fk_base_contract
             and    tpa.date_nach_vypl = tpp.date_nach_vypl
             and    tpa.ssylka_fl = tpp.ssylka_fl
           )
    where  tpp.fk_pay_portfolio is null
    and    tpp.true_kod_izm in ('Y', 'N');
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_portfolios');
      raise;
  end create_portfolios;
  
  /**
   * Процедура создает PAY_DECISIONS
   */
  procedure create_pay_decisions(
    p_err_tag varchar2
  ) is
    l_creation_date date;
  begin
    l_creation_date := sysdate;
    insert into pay_decisions(
      fk_pay_portfolio,
      fk_decision_type,
      decision_number,
      decision_date,
      amount,
      pay_start,
      pay_stop,
      fk_pension_agreement,
      creation_date,
      fk_operator,
      fk_contract
    ) select tpp.fk_pay_portfolio,
             6,
             -1 * tpp.ssylka_fl,
             tpp.change_date,
             pa.pa_amount,
             pa.effective_date,
             pa.expiration_date,
             pa.fk_contract,
             l_creation_date,
             53,
             pa.fk_base_contract
      from   transform_pa_portfolios tpp,
             transform_pa            tpa,
             pension_agreements_v    pa
      where  1=1
      and    pa.fk_contract = tpa.fk_contract
      and    tpa.date_nach_vypl = tpp.date_nach_vypl
      and    tpa.ssylka_fl = tpp.ssylka_fl
      and    tpp.true_kod_izm in ('Y', 'N')
      and    tpp.fk_pay_portfolio is not null
      and    tpp.fk_pay_decision is null
    log errors into ERR$_IMP_PAY_DECISIONS (p_err_tag) reject limit unlimited;
    
    put('create_pay_decisions: inserted ' || sql%rowcount || ' row(s)');
    
    update transform_pa_portfolios tpp
    set    tpp.fk_pay_decision = (
             select pd.id
             from   transform_pa           tpa,
                    pay_decisions          pd
             where  1=1
             and    pd.creation_date = l_creation_date
             and    pd.fk_pension_agreement = tpa.fk_contract
             and    pd.fk_pay_portfolio = tpp.fk_pay_portfolio
             and    tpa.date_nach_vypl = tpp.date_nach_vypl
             and    tpa.ssylka_fl = tpp.ssylka_fl
           )
    where  tpp.fk_pay_portfolio is not null
    and    tpp.fk_pay_decision is null
    and    tpp.true_kod_izm in ('Y', 'N');
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_pay_decisions');
      raise;
  end create_pay_decisions;
  
  
  /**
   * Процедура импорта пенс.соглашений, по которым были начисления в заданном периоде (мин. квант - месяц)
   *   Поддерживается многоразовый запуск за один период
   *
   *  Разовый запуск:
   *    begin
   *      log_pkg.enable_output;
   *      import_assignments_pkg.import_pension_agreements(
   *        p_from_date => to_date(19800101, 'yyyymmdd'),
   *        p_to_date   => sysdate
   *      );
   *    exception
   *      when others then
   *        log_pkg.show_errors_all;
   *        raise;
   *    end;
   *
   *  Просмотр не импортированных соглашений:
   *    select * from transform_pa tpa where nvl(tpa.fk_contract, 0) > 0
   *  Просмотр ошибок импорта:
   *    select * from ERR$_IMP_DOCUMENTS where ORA_ERR_TAG$ = &l_err_tag;
   *    select * from ERR$_IMP_CONTRACTS where ORA_ERR_TAG$ = &l_err_tag;
   *    select * from ERR$_IMP_PENSION_AGREEMENTS where ORA_ERR_TAG$ = &l_err_tag;
   *  l_err_tag - выводится в output
   */
  procedure import_pension_agreements(
    p_from_date date,
    p_to_date   date,
    p_commit    boolean default true
  ) is
    l_err_tag varchar(250);
    -- update_transform
    procedure update_transform_contragents_ is
      pragma autonomous_transaction;
    begin
      update transform_contragents tc
      set    tc.ssylka_ts = tc.ssylka_fl,
             tc.ssylka_fl = tc.ssylka_ts --297214
      where  tc.ssylka_fl = 2013709;
      
      update pension_agreements pa
      set    pa.effective_date = to_date('17.05.2017', 'dd.mm.yyyy')
      where  pa.fk_contract = 12128925
      and    pa.effective_date <> to_date('17.05.2017', 'dd.mm.yyyy');
      
      commit;
    end update_transform_contragents_;
    
    procedure update_pd_arh_ is
    begin
      update fnd.sp_pen_dog_arh pda
      set    pda.shema_dog = coalesce(
               (select pd.shema_dog from fnd.sp_pen_dog pd where pd.ssylka = pda.ssylka),
               (select tc.fk_scheme from gazfond.transform_contragents tc where tc.ssylka_fl = pda.ssylka)
             )
      where  pda.shema_dog is null;
      commit;
    end update_pd_arh_;
    --
  begin
    --
    init_exception;
    l_err_tag := 'ImportPA_' || to_char(sysdate, 'yyyymmddhh24miss');
    put('create_pension_agreements: l_err_tag = ' || l_err_tag);
    update_transform_contragents_;
    update_pd_arh_;
    --
    insert_transform_pa(trunc(p_from_date, 'MM'), add_months(trunc(p_to_date, 'MM'), 1) - 1);
    if p_commit then
      commit;
    end if;
    --
    create_pension_agreements(p_err_tag => l_err_tag);
    if p_commit then
      commit;
    end if;
    
    insert_transform_pa_portfolio;
    if p_commit then
      commit;
    end if;
    
    create_portfolio_docs(p_err_tag => l_err_tag);
    if p_commit then
      commit;
    end if;
    
    create_portfolios(p_err_tag => l_err_tag);
    if p_commit then
      commit;
    end if;
    
    create_pay_decisions(p_err_tag => l_err_tag);
    if p_commit then
      commit;
    end if;
    
    /*
    gather_table_stats('CONTRACTS');
    gather_table_stats('DOCUMENTS');
    gather_table_stats('PENSION_AGREEMENTS');
*/
  exception
    when others then
      rollback;
      fix_exception($$PLSQL_LINE, 'import_pension_agreements(' || to_char(p_from_date, 'dd.mm.yyyy') || ',' || to_char(p_from_date, 'dd.mm.yyyy') || ')');
      raise;
  end import_pension_agreements;
  
  /**
   */
  procedure create_pa_addendums(
    p_err_tag varchar2
  ) is
  begin
    merge into pension_agreement_addendums paa
    using (select pag.fk_contract fk_pension_agreement,
                  coalesce(
                    rdn.ref_kodinsz ,
                    rdn.kod_sr      ,
                    rdn.kod_insz
                  )               fk_base_doc,
                  coalesce(
                    pag.fk_debit, 
                    import_assignments_pkg.get_sspv_id(pag.fk_scheme)
                  )               fk_provacct,
                  ipd.nom_izm     serialno,
                  ipd.summa_izm   amount,
                  greatest(ipd.data_izm, pag.effective_date) alt_date_begin,
                  ipd.dat_zanes   creation_date
           from   fnd.sp_izm_pd_v ipd
             join transform_contragents tc
             on   tc.ssylka_fl = ipd.ssylka_fl
             join pension_agreements_imp_v pag
             on   pag.fk_base_contract = tc.fk_contract
             and  ipd.data_izm between 
                    case when pag.rn = 1 then to_date(19000101, 'yyyymmdd') else pag.effective_date end 
                    and 
                    case when pag.rn = cnt then to_date(21000101, 'yyyymmdd') else coalesce(pag.effective_date_next - 1, ipd.data_izm) end
             left join fnd.reer_doc_ngpf rdn
             on   rdn.ssylka = ipd.ssylka_doc
           where ipd.nom_izm > 0
          ) u
    on    (paa.fk_pension_agreement = u.fk_pension_agreement and paa.serialno = u.serialno)
    when not matched then
      insert (
        id,
        fk_pension_agreement,
        fk_base_doc,
        fk_provacct,
        serialno,
        amount,
        alt_date_begin,
        creation_date
      ) values (
        pension_agreement_addendum_seq.nextval,
        u.fk_pension_agreement,
        u.fk_base_doc,
        u.fk_provacct,
        u.serialno,
        u.amount,
        u.alt_date_begin,
        u.creation_date
      )
    log errors into ERR$_PENSION_AGREEMENT_ADDEND (p_err_tag) reject limit unlimited;
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_pa_addendums');
      raise;
  end create_pa_addendums;
  
  /**
   * Процедура создает записи pension_agreements_addendums с cerilno = 0 - начальные значения пенсии
   */
  procedure create_init_addendums(
    p_err_tag varchar2
  ) is
  begin
    
    merge into pension_agreement_addendums paa
    using (select pa.fk_contract,
                  pa.effective_date,
                  pa.fk_debit,
                  case when pa.fk_scheme in (1, 5, 6) then import_assignments_pkg.get_sspv_id(pa.fk_scheme) end fk_sspv,
                  pa.pa_amount,
                  pa.creation_date
           from   pension_agreements_v pa
          ) u
    on    (paa.fk_pension_agreement = u.fk_contract and paa.serialno = 0)
    when not matched then
      insert(
        id,
        fk_pension_agreement,
        fk_base_doc,
        fk_provacct,
        serialno,
        canceled,
        amount,
        alt_date_begin,
        creation_date
      ) values (
        pension_agreement_addendum_seq.nextval,
        u.fk_contract,
        u.fk_contract,
        coalesce(u.fk_debit, u.fk_sspv),
        0,
        0,
        u.pa_amount,
        u.effective_date,
        u.creation_date --более ставить нечего при импорте...
      )
    log errors into ERR$_PENSION_AGREEMENT_ADDEND (p_err_tag) reject limit unlimited;
    
    put('create_init_addendums: добавлено ' || sql%rowcount || ' начальных значений');
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_init_addendums');
      raise;
  end create_init_addendums;
  
  /**
   */
  procedure canceled_pa_addendums is
  begin
    update (
      select paa.id, paa.canceled, paa.canceled_new
      from (
              select paa.id,
                     paa.fk_pension_agreement,
                     paa.serialno,
                     paa.canceled,
                     coalesce(
                       (select min(paa2.serialno)
                        from   pension_agreement_addendums paa2
                        where  1=1
                        and    paa2.serialno > paa.serialno
                        and    paa2.alt_date_begin <= paa.alt_date_begin
                        and    paa2.fk_pension_agreement = paa.fk_pension_agreement
                       ),
                       0
                     ) canceled_new,
                     paa.amount,
                     paa.alt_date_begin,
                     paa.alt_date_end,
                     paa.creation_date
              from   pension_agreement_addendums paa
              where  paa.fk_pension_agreement in (
                       select pa.fk_contract
                       from   pension_agreements_v pa
                     )
           ) paa
      where paa.canceled <> paa.canceled_new
    ) paa
    set paa.canceled = paa.canceled_new;
    
    put('canceled_pa_addendums: признак отмены обновлен в ' || sql%rowcount || ' строках');

  exception
    when others then
      fix_exception($$PLSQL_LINE, 'canceled_pa_addendums');
      raise;
  end canceled_pa_addendums;

  /**
  * Процедура импорта изменений к пенс.соглашениям
  *  Разовый запуск:
  *    begin
  *      log_pkg.enable_output;
  *      import_assignments_pkg.import_pa_addendums;
  *    exception
  *      when others then
  *        log_pkg.show_errors_all;
  *        raise;
  *    end;
  *
  *  l_err_tag - выводится в output
  */
  procedure import_pa_addendums(
    p_commit    boolean default true
  ) is
    l_err_tag varchar(250);
    
  begin
    --
    init_exception;
    l_err_tag := 'ImportPA_' || to_char(sysdate, 'yyyymmddhh24miss');
    put('import_pa_addendums: l_err_tag = ' || l_err_tag);
    --
    create_pa_addendums(l_err_tag);
    create_init_addendums(l_err_tag);
    canceled_pa_addendums;
    --
    if p_commit then
      commit;
    end if;
    --
    
    gather_table_stats('PENSION_AGREEMENT_ADDENDUMS');
    
  exception
    when others then
      rollback;
      fix_exception($$PLSQL_LINE, 'import_pa_addendums');
      raise;
  end import_pa_addendums;
  
  /**
   * Процедура заполняет таблицу TRANSFORM_PA_RESTRICTIONS, данными из FND
   */
  procedure insert_transform_rest(
    p_import_id varchar2
  ) is
  begin
    
    insert into transform_pa_restrictions(
      import_id, 
      ssylka, 
      fk_contragent, 
      fk_contract, 
      kod_ogr_pv, 
      primech,
      nach_deistv,
      okon_deistv,
      fnd_nach_deistv,
      fnd_okon_deistv,
      fk_pay_restriction,
      is_cancel
    ) select p_import_id,
             op.ssylka_fl,
             tc.fk_contragent,
             pa.fk_contract,
             op.kod_ogr_pv,
             op.primech,
             op.nach_deistv,
             op.okon_deistv,
             op.real_nach_deistv,
             op.real_okon_deistv,
             (select pr.id --специально оставил подзапрос, чтобы при задвоении поднимало ошибку
              from   pay_restrictions pr
              where  pr.fk_doc_with_acct = pa.fk_contract
              and    pr.effective_date = op.nach_deistv
             ) fk_pay_restriction,
             op.is_cancel
      from   fnd.sp_ogr_pv_imp_v   op,
             transform_contragents tc,
             pension_agreements    pa
      where  1 = 1
      and    pa.effective_date = op.data_nach_vypl
      and    pa.fk_base_contract = tc.fk_contract
      and    tc.ssylka_fl = op.ssylka_fl
      and    op.nach_deistv < to_date(20500101, 'yyyymmdd')
      and    op.cnt = op.rn;

    put('insert_transform_rest: добавлено строк: ' || sql%rowcount);
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'insert_transform_rest');
      raise;
  end insert_transform_rest;
  
  /**
   * Процедура заполняет создает ограничения PAY_RESTRICTIONS
   */
  procedure create_pay_restrictions(
    p_import_id varchar2,
    p_err_tag   varchar2
  ) is
  begin
    
    insert into pay_restrictions(
      id,
      fk_doc_with_action,
      fk_document_cancel,
      fk_doc_with_acct,
      effective_date,
      expiration_date,
      remarks,
      islimited,
      fk_contract,
      creation_date
    ) select pay_restriction_seq.nextval,
             GC_PR_DOC_INIT,
             case when tpr.is_cancel = 'Y' then GC_PR_DOC_CANCEL end,
             tpr.fk_contract,
             tpr.nach_deistv,
             tpr.okon_deistv,
             p_import_id || '#' || tpr.kod_ogr_pv || '#' || tpr.primech,
             null,
             null,
             sysdate
      from   transform_pa_restrictions tpr
      where  1=1
      and    tpr.fk_pay_restriction is null
      and    tpr.import_id = p_import_id
    log errors into ERR$_IMP_PAY_RESTRICTIONS (p_err_tag) reject limit unlimited;
  
    put('create_pay_restrictions: добавлено строк: ' || sql%rowcount);
    
    update transform_pa_restrictions tpr
    set    tpr.fk_pay_restriction = (
             select pr.id
             from   pay_restrictions          pr
             where  1=1
             and    substr(pr.remarks, 16, instr(pr.remarks, '#', 17) - 16) = tpr.kod_ogr_pv
             and    substr(pr.remarks, 1, 14) = tpr.import_id
             and    pr.effective_date = tpr.nach_deistv
             and    pr.fk_doc_with_acct = tpr.fk_contract
           )
    where  tpr.import_id = p_import_id
    and    tpr.fk_pay_restriction is null;
    
    update pay_restrictions pr
    set    pr.remarks = substr(pr.remarks, instr(pr.remarks, '#', 17), length(pr.remarks))
    where  1=1
    and    substr(pr.remarks, 1, 14) = p_import_id
    and    pr.id in (
             select tpr.fk_pay_restriction
             from   transform_pa_restrictions tpr
             where  tpr.import_id = p_import_id
           );
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_pay_restrictions(' || p_import_id || '): ');
      raise;
  end create_pay_restrictions;
  
  /**
   * Процедура заполняет создает ограничения PAY_RESTRICTIONS
   */
  procedure update_pay_restrictions(
    p_import_id varchar2,
    p_err_tag   varchar2
  ) is
  begin
    
    merge into pay_restrictions pr
    using (select pr.id,
                  case
                    when t.okon_deistv is not null and t.okon_deistv > t.nach_deistv then
                      t.okon_deistv
                  end okon_deistv,
                  t.is_cancel
           from   transform_pa_restrictions t,
                  pay_restrictions          pr
           where  pr.id = t.fk_pay_restriction
           and    (
                   (pr.fk_document_cancel is null and t.is_cancel = 'Y')        
                   or
                   (t.okon_deistv > t.nach_deistv and coalesce(t.okon_deistv, to_date(99991231, 'yyyymmdd')) <> coalesce(pr.expiration_date, to_date(99991231, 'yyyymmdd')))
                  )
           and    t.import_id = p_import_id
          ) u
    on    (pr.id = u.id)
    when matched then
      update set
        pr.fk_document_cancel = case when u.is_cancel = 'Y' then GC_PR_DOC_CANCEL else pr.fk_document_cancel end,
        pr.expiration_date = coalesce(u.okon_deistv, pr.expiration_date)
    log errors into ERR$_IMP_PAY_RESTRICTIONS (p_err_tag) reject limit unlimited;
    
    put('update_pay_restrictions: обновлено строк: ' || sql%rowcount);
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'update_pay_restrictions(' || p_import_id || '): ');
      raise;
  end update_pay_restrictions;

  /**
  * Процедура импорта ограничений выплат
  *  Разовый запуск:
  *    begin
  *      log_pkg.enable_output;
  *      import_assignments_pkg.import_pay_restrictions;
  *    exception
  *      when others then
  *        log_pkg.show_errors_all;
  *        raise;
  *    end;
  *
  *  l_err_tag - выводится в output
  */
  procedure import_pay_restrictions(
    p_commit    boolean default true
  ) is
    l_err_tag varchar(250);
    l_import_id varchar2(14);
  begin
    --
    init_exception;
    l_import_id := to_char(sysdate, 'yyyymmddhh24miss');
    l_err_tag := 'ImportPA_' || l_import_id;
    put('import_pay_restrictions: l_import_id = ' || l_import_id);
    put('import_pay_restrictions: l_err_tag = ' || l_err_tag);
    --
    insert_transform_rest(p_import_id => l_import_id);
    create_pay_restrictions(p_import_id => l_import_id, p_err_tag => l_err_tag);
    update_pay_restrictions(p_import_id => l_import_id, p_err_tag => l_err_tag);
    --
    if p_commit then
      commit;
    end if;
    --
    
    --gather_table_stats('PAY_RESTRICTIONS');
    
  exception
    when others then
      rollback;
      fix_exception($$PLSQL_LINE, 'import_pa_addendums');
      raise;
  end import_pay_restrictions;
  
  /**
   * Процедура заполняет таблицу TRANSFORM_PA_ACCOUNTS, данными из FND
   */
  procedure insert_transform_pa_accounts(
    p_from_date date,
    p_to_date   date
  ) is
  begin
    put('Start insert transform accounts: ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
    merge into transform_pa_accounts acc
    using (select 'Cr' account_type,
                  pd.ssylka,
                  pa.fk_scheme,
                  pa.effective_date,
                  tc.fk_contragent,
                  pa.fk_base_contract,
                  pa.fk_contract,
                  pa.cntr_number,
                  pa.expiration_date,
                  pd.source_table
           from   fnd.sp_pen_dog_imp_v pd,
                  transform_contragents tc,
                  pension_agreements_v  pa
           where  1=1
           and    pa.fk_credit is null
           and    pa.effective_date = pd.data_nach_vypl
           and    pa.fk_base_contract = tc.fk_contract
           and    tc.ssylka_fl = pd.ssylka
           and    exists (
                    select 1
                    from   fnd.vypl_pen vp
                    where  1=1
                    and    vp.data_op between p_from_date and p_to_date
                    and    vp.data_nachisl between pd.from_date and pd.to_date
                    and    vp.ssylka_fl = pd.ssylka
                  )
          union all
           select 'Db' account_type,
                  pd.ssylka,
                  pa.fk_scheme,
                  pa.effective_date,
                  tc.fk_contragent,
                  pa.fk_base_contract,
                  pa.fk_contract,
                  pa.cntr_number,
                  pa.expiration_date,
                  pd.source_table
           from   fnd.sp_pen_dog_imp_v      pd,
                  transform_contragents tc,
                  pension_agreements_v  pa
           where  1 = 1
           and    fk_debit is null
           and    pa.effective_date = pd.data_nach_vypl
           and    pa.fk_base_contract = tc.fk_contract
           and    tc.ssylka_fl = pd.ssylka
           and    exists (
                    select 1
                    from   fnd.vypl_pen vp
                    where  1=1
                    and    vp.data_op between p_from_date and p_to_date
                    and    vp.data_nachisl between pd.from_date and pd.to_date
                    and    vp.ssylka_fl = pd.ssylka
                  )
           and    pd.shema_dog in (2, 3, 4, 5)
          ) u
    on    (acc.account_type = u.account_type and acc.ssylka_fl = u.ssylka and acc.pa_effective_date = u.effective_date)
    when not matched then
      insert(
        account_type        ,
        fk_scheme           ,
        ssylka_fl           ,
        pa_effective_date   ,
        fk_contragent       ,
        fk_base_contract    ,
        fk_contract         ,
        cntr_number         ,
        pa_expiration_date  ,
        source_table
      ) values (
        u.account_type,
        u.fk_scheme,
        u.ssylka, 
        u.effective_date,
        u.fk_contragent, 
        u.fk_base_contract,
        u.fk_contract,
        u.cntr_number,
        u.expiration_date,
        u.source_table
      )
    ;
    put('insert_transform_pa_accounts: добавлено строк: ' || sql%rowcount);
    put('Complete insert transform accounts: ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'insert_transform_pa_accounts(' || to_char(p_from_date, 'dd.mm.yyyy') || ',' || to_char(p_to_date, 'dd.mm.yyyy') || ')');
      raise;
  end insert_transform_pa_accounts;
  
  procedure create_account_actions is
    
    cursor l_accounts_cur is
      select a.fk_account,
             a.open_date,
             a.close_date,
             a.fk_opened,
             a.fk_closed,
             a.fk_contract,
             a.fk_contract_pa,
             a.account_type
      from   (
              select acc.id fk_account,
                     tac.pa_effective_date open_date,
                     case tac.source_table
                       when 'SP_PEN_DOG' then
                        lspv.data_zakr
                       else
                        (select pd.data_okon_vypl
                         from   fnd.sp_pen_dog_imp_v pd
                         where  pd.source_table = 'SP_PEN_DOG_ARH'
                         and    pd.ssylka = tac.ssylka_fl
                         and    pd.data_nach_vypl = tac.pa_effective_date)
                     end close_date,
                     acc.fk_opened,
                     acc.fk_closed,
                     tac.fk_contract,
                     tac.fk_contract fk_contract_pa,
                     tac.account_type
              from   transform_pa_accounts tac,
                     accounts              acc,
                     fnd.sp_lspv           lspv
              where  1 = 1
              and    lspv.ssylka_fl = tac.ssylka_fl
              and    acc.fk_acct_type = GC_ACCTYP_LSPV
              and    acc.fk_doc_with_acct = tac.fk_contract
              and    tac.fk_account is null
              and    tac.account_type = 'Cr'
             union all
              select acc.id fk_account,
                     tac.pa_effective_date open_date,
                     case tac.source_table
                       when 'SP_PEN_DOG' then
                        ips.data_zakr
                       else
                        (select pd.data_okon_vypl
                         from   fnd.sp_pen_dog_imp_v pd
                         where  pd.source_table = 'SP_PEN_DOG_ARH'
                         and    pd.ssylka = tac.ssylka_fl
                         and    pd.data_nach_vypl = tac.pa_effective_date)
                     end close_date,
                     acc.fk_opened,
                     acc.fk_closed,
                     tac.fk_base_contract fk_contract,
                     tac.fk_contract fk_contract_pa,
                     tac.account_type
              from   transform_pa_accounts tac,
                     accounts              acc,
                     fnd.sp_ips            ips
              where  1 = 1
              and    ips.tip_lits = 3
              and    ips.ssylka_fl = tac.ssylka_fl
              and    acc.fk_acct_type = GC_ACCTYP_IPS
              and    acc.fk_doc_with_acct = tac.fk_base_contract
              and    tac.fk_account is null
              and    tac.account_type = 'Db'
             ) a
      where  (a.fk_opened is null or (a.fk_closed is null and a.close_date  is not null));
    --
    type l_accounts_tbl_typ is table of l_accounts_cur%rowtype;
    l_accounts l_accounts_tbl_typ;
    --
    type l_actions_tbl_typ is table of actions%rowtype index by pls_integer;
    l_actions l_actions_tbl_typ;
    --
    --
    function add_action_(
      p_fk_action_type actions.fk_action_type%type,
      p_action_date    actions.action_date%type
    ) return actions.id%type is
    begin
      l_actions(l_actions.count + 1).id := action_seq.nextval();
      l_actions(l_actions.count).fk_action_type := p_fk_action_type;
      l_actions(l_actions.count).action_date    := p_action_date;
      l_actions(l_actions.count).fk_operator    := 0;
      return l_actions(l_actions.count).id;
    end add_action_;
    --
    --
    procedure flush_actions_(
      p_accounts in out nocopy l_accounts_tbl_typ
    ) is
    begin
      
      forall i in 1..l_actions.count
        insert into actions(
          id,
          action_date,
          fk_action_type,
          fk_operator
        ) values(
          l_actions(i).id,
          l_actions(i).action_date,
          l_actions(i).fk_action_type,
          l_actions(i).fk_operator
        );
      l_actions.delete;
      
      forall i in 1..p_accounts.count
        update accounts acc
        set    acc.fk_opened = p_accounts(i).fk_opened,
               acc.fk_closed = p_accounts(i).fk_closed
        where  acc.id = p_accounts(i).fk_account;
      
      forall i in 1..p_accounts.count
        update contracts cn
        set    cn.fk_account = p_accounts(i).fk_account
        where  cn.fk_document = p_accounts(i).fk_contract;
      
    exception
      when others then
        fix_exception($$PLSQL_LINE, 'flush_actions_');
        raise;
    end flush_actions_;
    --
  begin
    
    open l_accounts_cur;
    
    loop
      fetch l_accounts_cur
        bulk collect into l_accounts limit 10000;
      for i in 1..l_accounts.count loop
        if l_accounts(i).fk_opened is null then
          l_accounts(i).fk_opened := add_action_(
            p_fk_action_type => GC_ACT_OPEN_ACC,
            p_action_date    => l_accounts(i).open_date
          );
        end if;
        if l_accounts(i).fk_closed is null and l_accounts(i).close_date is not null then
          l_accounts(i).fk_closed := add_action_(
            p_fk_action_type => GC_ACT_CLOSE_ACC,
            p_action_date    => l_accounts(i).close_date
          );
        end if;
      end loop;
      flush_actions_(l_accounts);
      exit when l_accounts.count = 0;
    end loop;
    
    close l_accounts_cur;
    
    update transform_pa_accounts tac
    set    tac.fk_account = (
             select cn.fk_account
             from   contracts cn
             where  cn.fk_document = tac.fk_contract
           )
    where  tac.fk_account is null;
    
  exception
    when others then
      if l_accounts_cur%isopen then
        close l_accounts_cur;
      end if;
      fix_exception($$PLSQL_LINE, 'create_account_actions');
      raise;
  end create_account_actions;
  
  /**
   */
  procedure create_lspv(
    p_err_tag varchar2
  ) is
    
  begin
    --
    put('Start create LSPV: ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
    insert into accounts(
      id,
      acct_number,
      title,
      fk_acct_type,
      fk_scheme,
      fk_doc_with_acct,
      correct_aco,
      acct_index
    ) select account_seq.nextval,
             coalesce(t.acct_number, account_number_seq.nextval) acct_number, ---!!!!!!!!!!!!!!!!!
             t.title,
             GC_ACCTYP_LSPV fk_acct_type,
             t.fk_scheme,
             t.fk_doc_with_acct,
             case t.source_table
               when 'SP_PEN_DOG' then 
                 lspv.aktuar_def
             end  correct_aco,
             trim(to_char(lspv.nom_vkl, '0000')) || '/' || trim(to_char(lspv.nom_ips, '0000000'))
      from   (
              select tac.ssylka_fl,
                     tac.source_table,
                     case
                       when not(tac.source_table = 'SP_PEN_DOG_ARH' or acc.exists_account > 0) then
                         tac.ssylka_fl
                     end               acct_number,
                     lpad(to_char(tac.ssylka_fl), 7, '0')     title,
                     tac.fk_scheme     fk_scheme,
                     tac.fk_contract   fk_doc_with_acct
              from   transform_pa_accounts tac,
                     lateral(
                       select count(1) exists_account
                       from   accounts acc
                       where  acc.acct_number = tac.ssylka_fl
                       and    acc.fk_acct_type = GC_ACCTYP_LSPV
                     ) acc
              where  1=1
              and    not exists (
                       select 1
                       from   contracts cn
                       where  cn.fk_document = tac.fk_contract
                       and    cn.fk_account is not null
                     )
              and    tac.account_type = 'Cr'
              and    tac.fk_account is null
             ) t,
             fnd.sp_lspv lspv
      where  lspv.ssylka_fl = t.ssylka_fl
    log errors into ERR$_IMP_ACCOUNTS (p_err_tag) reject limit unlimited;
    
    put('Create ' || sql%rowcount || ' LSPV.');
    put('Complete create LSPV: ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
        
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_lspv(' || p_err_tag || ')');
      raise;
  end create_lspv;
  
  /**
   */
  procedure create_ips(
    p_err_tag varchar2
  ) is
    
  begin
    --
    put('Start create IPS: ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
    insert into accounts(
      id,
      acct_number,
      title,
      fk_acct_type,
      fk_scheme,
      fk_doc_with_acct,
      correct_aco,
      acct_index
    ) select account_seq.nextval,
             coalesce(t.acct_number, account_number_seq.nextval) acct_number, ---!!!!!!!!!!!!!!!!!
             t.title,
             GC_ACCTYP_IPS fk_acct_type,
             t.fk_scheme,
             t.fk_doc_with_acct,
             case t.source_table
               when 'SP_PEN_DOG' then 
                 ips.aktuar_def
             end  correct_aco,
             trim(to_char(ips.nom_vkl, '0000')) || '/' || trim(to_char(ips.nom_ips, '0000000'))
      from   (
              select tac.ssylka_fl,
                     tac.source_table,
                     case
                       when not(tac.source_table = 'SP_PEN_DOG_ARH' or acc.exists_account > 0) then
                         tac.ssylka_fl
                     end               acct_number,
                     lpad(to_char(tac.ssylka_fl), 7, '0') title,
                     tac.fk_scheme     fk_scheme,
                     tac.fk_base_contract   fk_doc_with_acct
              from   transform_pa_accounts tac,
                     lateral(
                       select count(1) exists_account
                       from   accounts acc
                       where  acc.acct_number = tac.ssylka_fl
                       and    acc.fk_acct_type = GC_ACCTYP_IPS
                     ) acc
              where  1=1
              and    not exists (
                       select 1
                       from   contracts cn
                       where  cn.fk_document = tac.fk_base_contract
                       and    cn.fk_account is not null
                     )
              and    tac.account_type = 'Db'
              and    tac.fk_account is null
             ) t,
             fnd.sp_ips ips
      where  ips.ssylka_fl = t.ssylka_fl
      and    ips.tip_lits = 3
    log errors into ERR$_IMP_ACCOUNTS (p_err_tag) reject limit unlimited;
    
    put('Create ' || sql%rowcount || ' IPS.');
    put('Complete create IPS: ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_ips(' || p_err_tag || ')');
      raise;
  end create_ips;
    
  
  
  /**
   * Процедура создания ЛСПВ
   *   Поддерживается многоразовый запуск за один период
   *
   *  Разовый запуск:
   *    begin
   *      log_pkg.enable_output;
   *      import_assignments_pkg.create_accounts(
   *        p_from_date => to_date(19800101, 'yyyymmdd'),
   *        p_to_date   => sysdate
   *      );
   *    exception
   *      when others then
   *        log_pkg.show_errors_all;
   *        raise;
   *    end;
   *
   *  Просмотр не импортированных соглашений:
   *    select * from transform_pa_accounts tpa where nvl(tpa.fk_account, 0) > 0
   *  Просмотр ошибок импорта:
   *    select * from ERR$_IMP_ACCOUNTS ea where ea.ORA_ERR_TAG$ = &l_err_tag;
   *  l_err_tag - выводится в output
   */
  procedure create_accounts(
    p_from_date date,
    p_to_date   date,
    p_commit    boolean default true
  ) is
    l_err_tag varchar(250);
  begin
    --
    init_exception;
    l_err_tag := 'CreateAccounts_' || to_char(sysdate, 'yyyymmddhh24miss');
    put('create_accounts: l_err_tag = ' || l_err_tag);
    --
    insert_transform_pa_accounts(trunc(p_from_date, 'MM'), add_months(trunc(p_to_date, 'MM'), 1) - 1);
    if p_commit then
      commit;
    end if;
    --
    create_lspv(p_err_tag => l_err_tag);
    create_ips(p_err_tag => l_err_tag);
    create_account_actions;
    --
    if p_commit then
      commit;
    end if;
    --
    --gather_table_stats('ACCOUNTS');
    --
  exception
    when others then
      rollback;
      fix_exception($$PLSQL_LINE, 'create_accounts(' || to_char(p_from_date, 'dd.mm.yyyy') || ',' || to_char(p_to_date, 'dd.mm.yyyy') || ')');
      raise;
  end create_accounts;
  
  /**
   * Процедура insert_transform_pa_asg создает документы-основания начислений (PAY_ORDER)
   *   заполняет таблицу transform_pa_assignments, создает DOCUMENTS и PAY_ORDERS 
   */
  procedure insert_transform_pa_asg(
    p_import_id varchar2,
    p_from_date date,
    p_to_date   date
  ) is
  begin
    
    merge into transform_pa_assignments tas
    using (select  trunc(vp.data_op) date_op
           from   fnd.vypl_pen_imp_v vp
           where  vp.data_op between p_from_date and p_to_date
           group by vp.data_op
           order by vp.data_op
          ) u
    on    (tas.date_op = u.date_op)
    when not matched then
      insert(date_op, import_id, fk_pay_order)
      values(u.date_op, p_import_id, document_seq.nextval)
    when matched then
      update set
        tas.import_id = case tas.state when 'N' then p_import_id else tas.import_id end
    ;
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'insert_transform_pa_asg(' || p_import_id || ',' || to_char(p_from_date, 'dd.mm.yyyy') || ',' || to_char(p_to_date, 'dd.mm.yyyy') || ')');
      raise;
  end insert_transform_pa_asg;
  
  /**
   * Процедура insert_transform_pa_asg создает документы-основания начислений (PAY_ORDER)
   *   заполняет таблицу transform_pa_assignments, создает DOCUMENTS и PAY_ORDERS 
   */
  procedure create_pay_orders(
    p_import_id varchar2,
    p_err_tag   varchar2
  ) is
    
  begin
    
    insert all
      when document_id is null then
        into documents(id, doc_date, title, is_accounting_doc)
        values (fk_pay_order, date_op, 'Импорт начислений FND, ' || to_char(date_op, 'dd.mm.yyyy'), 0)
        log errors into ERR$_IMP_DOCUMENTS (p_err_tag) reject limit unlimited
      when po_fk_pay_order is null then
        into pay_orders(fk_document, payment_period, operation_date, payment_freqmask, scheduled_date, calculation_date, fk_pay_order_type)
        values(fk_pay_order, trunc(date_op, 'MM'), date_op, GC_PAYMENT_FREQMASK, trunc(sysdate), sysdate, GC_PO_TYP_PENS)
        log errors into ERR$_IMP_PAY_ORDERS (p_err_tag) reject limit unlimited
    select d.id           document_id,
           po.fk_document po_fk_pay_order,
           fk_pay_order,
           date_op
    from   transform_pa_assignments tas,
           documents                d,
           pay_orders               po
    where  1=1
    and    po.fk_document(+) = tas.fk_pay_order
    and    d.id(+) = tas.fk_pay_order
    and    tas.import_id = p_import_id;
    
    if is_exists_error('ERR$_IMP_DOCUMENTS', p_err_tag) or is_exists_error('ERR$_IMP_PAY_ORDERS', p_err_tag) then
      fix_exception($$PLSQL_LINE, 'create_pay_orders(' || p_import_id || '): ' ||
        ' ошибки создания PAY_ORDERS, см. ERR$_IMP_DOCUMENTS / ERR$_IMP_PAY_ORDERS, ORA_ERR_TAG$ = ' || p_err_tag
      );
      raise program_error;
    end if;
    --*/
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_pay_orders(' || p_import_id || ')');
      raise;
  end create_pay_orders;
  
  /**
   * Процедура import_assignments импорт начислений
   */
  procedure import_assignments_period(
    p_import_id varchar2,
    p_err_tag   varchar2,
    p_period    date
  ) is
    l_err_tag varchar2(200);
  begin
    --put('Импорт начислений отключен!!! Не закончена логика определения даты и типа начисления (для однопериодных)');    return;
    l_err_tag := p_err_tag || '#' || to_char(p_period, 'yyyymmdd');
    
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
      asgmt_state,
      serv_doc,
      serv_date,
      comments
    ) select /*+ parallel(4)*/ assignment_seq.nextval,
             tas.fk_pay_order,
             pa.fk_contract,
             case 
               when pa.fk_scheme in (1, 6) or (pa.fk_scheme = 5 and vp.data_nachisl >= vp.data_perevoda_5_cx) then
                 import_assignments_pkg.get_sspv_id(pa.fk_scheme)
               else pa.fk_debit
             end fk_debit,
             pa.fk_credit,
             case
               when dbl.cnt = 0 then 2 --первичная выплата - всегда начисление пенсии
               else 7 --вторичные выплаты - доплаты!
             end   fk_asgmt_type,
             pa.fk_contragent,
             trunc(vp.data_nachisl, 'MM') + dbl.cnt,
             vp.summa,
             GC_PAY_CODE_PENSION, --5000 CDM.PAY_CODES
             coalesce(vp.oplach_dni, 0),
             pa.fk_scheme,
             1 asgmt_state, --ASSIGNMENT_STATES
             pa.fk_contract serv_doc,
             trunc(vp.data_nachisl, 'MM') + dbl.cnt serv_date,
             to_char(vp.tip_vypl) || '/' || to_char(vp.data_nachisl, 'yyyymmdd') comments
      from   transform_pa_assignments tas,
             fnd.vypl_pen_imp_v       vp,  --NEWVIEW vypl_pen_v
             pension_agreements_v     pa,
             lateral(
               select count(1) cnt
               from   fnd.vypl_pen vp2
               where  1 = 1
               and    (
                        vp2.data_op < vp.data_op
                       or 
                        (vp2.data_op = vp.data_op and vp2.tip_vypl < vp.tip_vypl) 
                       or 
                        (vp2.data_op = vp.data_op and vp2.tip_vypl = vp.tip_vypl and vp2.data_nachisl < vp.data_nachisl)
                      )
               and    trunc(vp2.data_nachisl, 'MM') = trunc(vp.data_nachisl, 'MM')
               and    vp2.ssylka_fl = vp.ssylka_fl
               and    vp2.data_op <= vp.data_op
             ) dbl
      where  1=1
      and    pa.fk_contract = vp.ref_kodinsz
      and    vp.data_op = tas.date_op
      and    trunc(tas.date_op, 'MM') = p_period --to_date(&p_period, 'yyyymmdd')--p_period
      and    tas.state = 'W'
      and    tas.import_id = p_import_id
    log errors into ERR$_IMP_ASSIGNMENTS (l_err_tag) reject limit 0;
    
    put('За период ' || to_char(p_period, 'dd.mm.yyyy') || ' импортировано ' || sql%rowcount || ' начислений');
    
    if is_exists_error('ERR$_IMP_ASSIGNMENTS', l_err_tag) then
      fix_exception($$PLSQL_LINE, 'import_assignments_period (' || to_char(p_period, 'dd.mm.yyyy') || ',' || p_import_id || ',' || p_err_tag || '): ' ||
        ' есть ошибки импорта, см. ERR$_IMP_ASSIGNMENTS.ORA_ERR_TAG$ = ' || l_err_tag
      );
      /*
      TODO: owner="V.Zhuravov" created="27.07.2018"
      text="raise отключен на период тестирования"
      */
      --raise program_error;
    end if;
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'import_assignments_period(' || to_char(p_period, 'dd.mm.yyyy') || ',' || p_import_id || ', ' || p_err_tag || '): ' || l_err_tag);
      raise;
  end import_assignments_period;
  
  /**
   * Процедура import_assignments запуск импорта начислений по периодам
   */
  procedure import_assignments(
    p_import_id varchar2,
    p_err_tag   varchar2
  ) is
    
    l_periods sys.odcidatelist;
    
    procedure set_state_complete_(
      p_period date,
      p_state  varchar2
    ) is
    begin
      update transform_pa_assignments tas
      set    tas.state = p_state,
             tas.creation_date = case when p_state = 'W' then sysdate else tas.creation_date end,
             tas.last_update_date = sysdate
      where  tas.import_id = p_import_id
      and    exists(
               select 1
               from   pay_orders po
               where  po.fk_document = tas.fk_pay_order
               and    po.payment_period = p_period
             );
      commit;
    exception
      when others then
        rollback;
        fix_exception($$PLSQL_LINE, 'set_state_complete_: Fatal error');
        raise;
    end set_state_complete_;
    
    procedure set_state_complete_at_(
      p_period date,
      p_state  varchar2
    ) is
      pragma autonomous_transaction;
    begin
      set_state_complete_(p_period, p_state);
      commit;
    exception
      when others then
        rollback;
        raise;
    end set_state_complete_at_;
    
  begin
    select po.payment_period
    bulk collect into l_periods
    from   transform_pa_assignments tas,
           pay_orders               po
    where  po.fk_document = tas.fk_pay_order
    and    tas.import_id = p_import_id
    group by po.payment_period
    order by po.payment_period;
    
    for i in 1..l_periods.count loop
      begin
        set_state_complete_(l_periods(i), 'W');
        import_assignments_period(
          p_import_id => p_import_id,
          p_err_tag   => p_err_tag,
          p_period    => l_periods(i)
        );
        set_state_complete_(l_periods(i), 'C');
      exception
        when others then
          rollback;
          set_state_complete_at_(l_periods(i), 'E');
          raise program_error;
      end;
    end loop;
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'import_assignments(' || p_import_id || ',' || p_err_tag || ')');
      raise;
  end import_assignments;
  
  /**
   * Процедура импорта выплат import_assignments
   *   Поддерживается многоразовый запуск за один период
   *
   * p_from_date - дата первого начисления (месяц)
   * p_to_date   - дата последнего начисления (месяц)
   * p_commit    - boolean, def: TRUE
   * 
   *  Разовый запуск:
   *    begin
   *      log_pkg.enable_output;
   *      import_assignments_pkg.import_assignments(
   *        p_from_date => to_date(19960101, 'yyyymmdd'),
   *        p_to_date   => to_date(19961231, 'yyyymmdd')
   *      );
   *    exception
   *      when others then
   *        log_pkg.show_errors_all;
   *        raise;
   *    end;
   *
   *  Просмотр не импортированных соглашений:
   *    select * from transform_pa_accounts tpa where nvl(tpa.fk_account, 0) > 0
   *  Просмотр ошибок импорта:
   *    select * from ERR$_IMP_PAY_ORDERS ea where ea.ORA_ERR_TAG$ = &l_err_tag;
   *    select * from ERR$_IMP_ASSIGNMENTS ea where ea.ORA_ERR_TAG$ = &l_err_tag;
   *    
   *  l_err_tag - выводится в output
   */
  procedure import_assignments(
    p_from_date date,
    p_to_date   date
  ) is
    l_import_id varchar2(14);
    l_err_tag   varchar(250);
    l_to_date   date;
  begin
    --
    
    init_exception;
    l_import_id := to_char(sysdate, 'yyyymmddhh24miss');
    l_err_tag := 'CreateAccounts_' || l_import_id;
    l_to_date := add_months(trunc(p_to_date, 'MM'), 1) - 1;
    
    put('Start import assignments: ' || to_char(p_from_date, 'dd.mm.yyyy') || ' - ' || to_char(p_to_date, 'dd.mm.yyyy'));
    put('  l_import_id = ' || l_import_id);
    put('  l_err_tag   = ' || l_err_tag);
    
    
    insert_transform_pa_asg(
      p_import_id => l_import_id, 
      p_from_date => trunc(p_from_date, 'MM'), 
      p_to_date   => l_to_date
    );
    commit;
    --return;
    create_pay_orders(p_import_id => l_import_id, p_err_tag => l_err_tag);
    
    commit;
    
    import_assignments(p_import_id => l_import_id, p_err_tag => l_err_tag);
    
    commit;
    
    gather_table_stats('ASSIGNMENTS');
    gather_table_stats('PAY_ORDERS');
    
  exception
    when others then
      rollback;
      fix_exception($$PLSQL_LINE, 'import_assignments(' || to_char(p_from_date, 'dd.mm.yyyy') || ',' || to_char(p_from_date, 'dd.mm.yyyy') || ')');
      raise;
  end import_assignments;
  
end import_assignments_pkg;
/
