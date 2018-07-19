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
   * Процедура создает пенс.соглашения по необработанным записям TRANSFORM_PA (флаг TRANSFORM_PA.IS_NEW)
   */
  procedure create_pension_agreements is
  begin
    null;
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'create_pension_agreements');
      raise;
  end create_pension_agreements;
  
  /**
   * Процедура импорта пенс.соглашений, по которым были начисления в заданном периоде (мин. квант - месяц)
   */
  procedure import_pension_agreements(
    p_from_date date,
    p_to_date   date
  ) is
  begin
    --
    insert_transform_pa(p_from_date, p_to_date);
    create_pension_agreements;
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception($$PLSQL_LINE, 'import_pension_agreements(' || to_char(p_from_date, 'dd.mm.yyyy') || ',' || to_char(p_from_date, 'dd.mm.yyyy') || ')');
      raise;
  end import_pension_agreements;
  
end import_assignments_pkg;
/
