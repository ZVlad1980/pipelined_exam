PL/SQL Developer Test script 3.0
83
-- Created on 24.08.2018 by V.ZHURAVOV 
declare 
  C_PAY_DATE constant date := to_date(20180731, 'yyyymmdd');
  C_TASK_NAME constant varchar2(50) := 'INSERT_ASSIGNMENTS';
  -- Local variables here
  procedure create_list(
    p_pay_date date
  ) is
  begin
    execute immediate 'truncate table agreements_list_t';
    insert into agreements_list_t(
      id,
      fk_contract,
      period_code,
      fk_debit,
      fk_credit,
      fk_scheme,
      fk_contragent,
      effective_date,
      last_pay_date,
      creation_date 
    ) select /*+ parallel(4)*/
             rownum,
             fk_contract,
             period_code,
             fk_debit,
             fk_credit,
             fk_scheme,
             fk_contragent,
             effective_date,
             least(last_pay_date, p_pay_date) last_pay_date, --окнечная дата зависит от period_code
             pa.creation_date
      from   pension_agreements_charge_v pa 
      where  pa.effective_date <= p_pay_date
      --and    rownum < 10001
      ;
    commit;
    dbms_stats.gather_table_stats(user, upper('agreements_list_t'), cascade => true);
  end create_list;
begin
  create_list(last_day(C_PAY_DATE));   return;
  begin
    dbms_parallel_execute.drop_task(task_name => 'INSERT_ASSIGNMENTS');
  exception
    when others then
      null;
  end;
  -- Test statements here
  
  dbms_parallel_execute.create_task(
    task_name => C_TASK_NAME
  );
  dbms_parallel_execute.create_chunks_by_number_col(
      task_name    => 'INSERT_ASSIGNMENTS',
      table_owner  => user,
      table_name   => 'AGREEMENTS_LIST_T',
      table_column => upper('id'),
      chunk_size   => 500
    );
  --*/
  --/*
  execute immediate 'truncate table pay_gfnpo_logs';
  dbms_parallel_execute.run_task(
    task_name                  => 'INSERT_ASSIGNMENTS',
    sql_stmt                   => 'begin pay_gfnpo_pkg.fill_charges_by_agr_range(:start_id, :end_id); end;',
    language_flag              => dbms_sql.native,
    parallel_level             => 4
  );
  /*
  -- If there is an error, RESUME it for at most 2 times.
  L_try    := 0;
  L_status := DBMS_PARALLEL_EXECUTE.TASK_STATUS(C_TASK_NAME);
  WHILE(l_try < 2 and L_status != DBMS_PARALLEL_EXECUTE.FINISHED) 
  LOOP
    L_try := l_try + 1;
    DBMS_PARALLEL_EXECUTE.RESUME_TASK(C_TASK_NAME);
    L_status := DBMS_PARALLEL_EXECUTE.TASK_STATUS(C_TASK_NAME);
  END LOOP;
 
  -- Done with processing; drop the task
  DBMS_PARALLEL_EXECUTE.DROP_TASK(C_TASK_NAME);
  */
end;
0
0
