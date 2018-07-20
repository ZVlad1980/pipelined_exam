create or replace package body import_assignments_pkg is

  GC_UNIT_NAME   constant varchar2(32) := $$PLSQL_UNIT;
  
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
  end fix_exception;
  
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
                  pd.source_table
           from   (
                   select pd.ssylka, 
                          pd.data_nach_vypl,
                          pd.ref_kodinsz,
                          pd.source_table
                   from   fnd.sp_pen_dog_v pd,
                          fnd.sp_invalid_v inv
                   where  1=1
                   and    exists (
                            select 1
                            from   fnd.vypl_pen vp
                            where  1=1
                            and    vp.data_nachisl between pd.data_nach_vypl and least(coalesce(inv.pereosv, sysdate), coalesce(pd.data_okon_vypl_next, sysdate))--
                            and    vp.data_op between p_from_date and p_to_date
                            and    vp.ssylka_fl = pd.ssylka
                          )
                   and    inv.pereosv(+) between pd.data_nach_vypl and coalesce(pd.data_okon_vypl_next, sysdate)--
                   and    inv.ssylka_fl(+) = pd.ssylka
                  ) pd,
                  lateral(
                    select tc.fk_contract,
                           tc.fk_contragent
                    from   transform_contragents tc
                    where  1=1
                    and    tc.ssylka_fl = pd.ssylka
                  ) (+) tc
           where   1 = 1
           and     not exists (
                     select 1
                     from   pension_agreements    pa,
                            contracts             cn
                     where  1 = 1
                     and    cn.fk_document = pa.fk_contract
                     and    pa.effective_date = pd.data_nach_vypl
                     and    pa.fk_base_contract = tc.fk_contract
                   )
          ) u
    on    (pa.ssylka_fl = u.ssylka and pa.date_nach_vypl = u.data_nach_vypl)
    when not matched then
      insert(
        ssylka_fl,
        date_nach_vypl,
        fk_base_contract,
        fk_contragent,
        ref_kodinsz,
        source_table
      ) values (
        u.ssylka, 
        u.data_nach_vypl, 
        u.fk_contract,
        u.fk_contragent,
        u.ref_kodinsz,
        u.source_table
      )
    ;
    put('insert_transform_pa: добавлено строк: ' || sql%rowcount);
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
        into documents(id, fk_doc_type, doc_date, title, fk_doc_with_acct)
        values(ref_kodinsz, 2, cntr_date, doctitle, ref_kodinsz)
        log errors into ERR$_IMP_DOCUMENTS (p_err_tag) reject limit unlimited
      when cntr_exists = 'N' then
        into contracts(fk_document, cntr_number, cntr_index, cntr_date, title, fk_cntr_type, fk_workplace, fk_contragent,  fk_company, fk_scheme, fk_closed)
        values(ref_kodinsz, cntr_number, cntr_index,cntr_date, doctitle, C_FK_CONTRACT_TYPE, C_FK_WORKPLACE, fk_contragent, fk_company, fk_scheme, null)
        log errors into ERR$_IMP_CONTRACTS (p_err_tag) reject limit unlimited
      when 1 = 1 then
        into pension_agreements(fk_contract, effective_date, expiration_date, amount, delta_pen, fk_base_contract, period_code, years, state, isarhv)
        values (ref_kodinsz, date_nach_vypl, data_okon_vypl, razm_pen, delta_pen, fk_base_contract, period_code, years, state, isarhv)
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
           t.isarhv
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
           pd.data_okon_vypl,
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
           case when pd.source_table = 'SP_PEN_DOG_ARH' then 1 else 0 end isarhv
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
    order by tpa.ssylka_fl,
           tpa.date_nach_vypl
    ) t;
    
    update transform_pa tpa
    set    tpa.fk_contract = tpa.ref_kodinsz
    where  1=1
    and    exists(
             select 1
             from   pension_agreements pa
             where  pa.effective_date = tpa.date_nach_vypl
             and    pa.fk_contract = tpa.ref_kodinsz
           )
    and    tpa.fk_contract is null;
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_pension_agreements');
      raise;
  end create_pension_agreements;
  
  /**
   * Процедура создает пенс.соглашения по необработанным записям TRANSFORM_PA (fk_contract is null)
   */
  procedure create_portfolio(
    p_err_tag varchar2
  ) is
  begin
    null;
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_pension_agreements');
      raise;
  end create_portfolio;
  
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
  begin
    --
    l_err_tag := 'ImportPA_' || to_char(sysdate, 'yyyymmddhh24miss');
    put('create_pension_agreements: l_err_tag = ' || l_err_tag);
    --
    insert_transform_pa(trunc(p_from_date, 'MM'), add_months(trunc(p_to_date, 'MM'), 1) - 1);
    create_pension_agreements(p_err_tag => l_err_tag);
    create_portfolio(p_err_tag => l_err_tag);
    --
    if p_commit then
      commit;
    end if;
    --
  exception
    when others then
      rollback;
      fix_exception($$PLSQL_LINE, 'import_pension_agreements(' || to_char(p_from_date, 'dd.mm.yyyy') || ',' || to_char(p_from_date, 'dd.mm.yyyy') || ')');
      raise;
  end import_pension_agreements;
  
end import_assignments_pkg;
/
