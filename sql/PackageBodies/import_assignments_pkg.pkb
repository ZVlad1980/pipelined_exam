create or replace package body import_assignments_pkg is

  GC_UNIT_NAME   constant varchar2(32) := $$PLSQL_UNIT;
  
  GC_ACCTYP_LSPV constant number := 114;
  
  GC_ACT_OPEN_ACC  constant number := 50; --открытие счета
  GC_ACT_CLOSE_ACC constant number := 60; --закрытие счета
  
  GC_PAYMENT_FREQMASK constant pay_orders.payment_freqmask%type := '00001111';
  GC_PO_TYP_PENS      constant number                           := 5;
  
  GC_PAY_CODE_PENSION constant assignments.fk_paycode%type := 5000;
  
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
    relies_on(accounts)
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
        into documents(id, fk_doc_type, doc_date, title, fk_doc_with_acct, is_accounting_doc)
        values(ref_kodinsz, 2, cntr_date, doctitle, ref_kodinsz, 0)
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
    and    tpa.ref_kodinsz is not null
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
   * Процедура создает PAY_PORTFOLIOS, PAY_DECISIONS
   */
  procedure create_portfolio(
    p_err_tag varchar2
  ) is
  begin
    dbms_output.put_line('Создание портфолио и дезижн не реализовано (' || p_err_tag || ')');
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
    init_exception;
    l_err_tag := 'ImportPA_' || to_char(sysdate, 'yyyymmddhh24miss');
    put('create_pension_agreements: l_err_tag = ' || l_err_tag);
    --
    insert_transform_pa(trunc(p_from_date, 'MM'), add_months(trunc(p_to_date, 'MM'), 1) - 1);
    if p_commit then
      commit;
    end if;
    create_pension_agreements(p_err_tag => l_err_tag);
    --create_portfolio(p_err_tag => l_err_tag);
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
  
  
  
  /**
   * Процедура заполняет таблицу TRANSFORM_PA_ACCOUNTS, данными из FND
   */
  procedure insert_transform_pa_accounts(
    p_from_date date,
    p_to_date   date
  ) is
  begin
    dbms_output.put_line('Start insert transform accounts: ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
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
                  pd.source_table --*/
           from   fnd.sp_pen_dog_vypl_v pd,
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
                    where  1 = 1
                    and    vp.data_nachisl between pd.nach_vypl_pen and pd.data_okon_vypl
                    and    vp.ssylka_fl = pd.ssylka
                    and    vp.data_op between p_from_date and p_to_date
                  )
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
    dbms_output.put_line('Complete insert transform accounts: ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'insert_transform_pa_accounts(' || to_char(p_from_date, 'dd.mm.yyyy') || ',' || to_char(p_from_date, 'dd.mm.yyyy') || ')');
      raise;
  end insert_transform_pa_accounts;
  
  procedure create_account_actions is
    
    cursor l_accounts_cur is
      select a.fk_account,
             a.open_date,
             a.close_date,
             a.fk_opened,
             a.fk_closed,
             a.fk_contract
      from   (
              select acc.id fk_account,
                     tac.pa_effective_date open_date,
                     case tac.source_table
                       when 'SP_PEN_DOG' then
                        lspv.data_zakr
                       else
                        (select pd.data_okon_vypl
                         from   fnd.sp_pen_dog_vypl_v pd
                         where  pd.ssylka = tac.ssylka_fl
                         and    pd.data_nach_vypl = tac.pa_effective_date)
                     end close_date,
                     acc.fk_opened,
                     acc.fk_closed,
                     tac.fk_contract
              from   transform_pa_accounts tac,
                     accounts              acc,
                     fnd.sp_lspv           lspv
              where  1 = 1
              and    lspv.ssylka_fl = tac.ssylka_fl
              and    acc.fk_acct_type = 114
                    --and    (acc.fk_opened is null or acc.fk_closed is null)
              and    acc.fk_doc_with_acct = tac.fk_contract
              and    tac.fk_account is null
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
        update transform_pa_accounts tac
        set    tac.fk_account = p_accounts(i).fk_account
        where  tac.fk_contract = p_accounts(i).fk_contract;
      
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
  procedure create_pa_accounts(
    p_err_tag varchar2
  ) is
    
  begin
    --
    dbms_output.put_line('Start create accounts: ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
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
                     tac.ssylka_fl     title,
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
    
    dbms_output.put_line('Create ' || sql%rowcount || ' accounts.');
    dbms_output.put_line('Complete create accounts: ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
    
    create_account_actions;
    
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_pa_accounts(' || p_err_tag || ')');
      raise;
  end create_pa_accounts;
    
  
  
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
    create_pa_accounts(p_err_tag => l_err_tag);
    if p_commit then
      commit;
    end if;
    --
    if p_commit then
      commit;
    end if;
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
    using (select trunc(vp.data_op) date_op
           from   fnd.vypl_pen_v vp
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
    ) select assignment_seq.nextval,
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
             fnd.vypl_pen_v           vp,
             pension_agreements_v     pa,
             lateral(
               select count(1) cnt
               from   fnd.vypl_pen vp2
               where  1 = 1
               and    (vp2.data_op < vp.data_op or vp2.tip_vypl < vp.tip_vypl) --код типа выплаты значим только при одинаковой дате операции
               and    trunc(vp2.data_nachisl, 'MM') = trunc(vp.data_nachisl, 'MM')
               and    vp2.ssylka_fl = vp.ssylka
               and    vp2.data_op <= vp.data_op
             ) dbl
      where  1=1
      and    pa.fk_contract = vp.ref_kodinsz
      and    vp.data_op = tas.date_op
      and    trunc(tas.date_op, 'MM') = p_period --to_date(&p_period, 'yyyymmdd')--p_period
      and    tas.state = 'N'
      and    tas.import_id = p_import_id
    log errors into ERR$_IMP_ASSIGNMENTS (l_err_tag) reject limit 50;
    
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
      set    tas.state = p_state
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
        import_assignments_period(
          p_import_id => p_import_id,
          p_err_tag   => p_err_tag,
          p_period    => l_periods(i)
        );
        set_state_complete_(l_periods(i), 'C');
      exception
        when others then
          set_state_complete_at_(l_periods(i), 'E');
          rollback;
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
    
    create_pay_orders(p_import_id => l_import_id, p_err_tag => l_err_tag);
    
    commit;
    
    import_assignments(p_import_id => l_import_id, p_err_tag => l_err_tag);
    
  exception
    when others then
      rollback;
      fix_exception($$PLSQL_LINE, 'import_assignments(' || to_char(p_from_date, 'dd.mm.yyyy') || ',' || to_char(p_from_date, 'dd.mm.yyyy') || ')');
      raise;
  end import_assignments;
  
end import_assignments_pkg;
/
