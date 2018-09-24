declare
  
  /**
   * Сбор статистики по заданной таблице и ее индексам
   */
  procedure gather_table_stats(
    p_table_name varchar2
  ) is
    l_time number;
  begin
    l_time := dbms_utility.get_time;
    dbms_output.put('Start gather stats for ' || p_table_name || ' ... ');
    dbms_stats.gather_table_stats(user, p_table_name, cascade => true, degree => 4);
    dbms_output.put_line('Ok, duration: ' || to_char(dbms_utility.get_time - l_time) || ' ms');
  exception
    when others then
      dbms_output.put_line('Error: ' || sqlerrm);
  end gather_table_stats;
begin
  for t in (
    select ut.table_name
    from   user_tables ut
    where  ut.table_name in (
             upper('assignments'),
             upper('pay_orders'),
             upper('pay_constraints'),
             upper('pension_agreement_periods'),
             upper('accounts_balance')
           )
  ) loop
    gather_table_stats(upper(t.table_name));
  end loop;
end;
