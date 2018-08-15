declare
  procedure gather_table_stats_(
    p_table_name varchar2
  ) is
    l_time number;
  begin
    l_time := dbms_utility.get_time;
    dbms_output.put('Start gather stats for ' || p_table_name || ' ... ');
    dbms_stats.gather_table_stats(user, p_table_name);
    dbms_output.put_line('Ok, duration: ' || to_char(dbms_utility.get_time - l_time) || ' ms');
  exception
    when others then
      dbms_output.put_line('Error: ' || sqlerrm);
      raise;
  end gather_table_stats_;
begin
  gather_table_stats_('ASSIGNMENTS');
  gather_table_stats_('PAY_ORDERS');
  gather_table_stats_('CONTRACTS');
  gather_table_stats_('DOCUMENTS');
  gather_table_stats_('PENSION_AGREEMENTS');
  gather_table_stats_('ACCOUNTS');
end;
/
--select dbms_stats.get_prefs('CASCADE') from dual;
