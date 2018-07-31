declare
  procedure start_(
    p_from_date date,
    p_to_date   date
  ) is
  begin
    update transform_pa_assignments tas
    set    tas.state = 'N'
    where  tas.state = 'E'
    and    tas.date_op between p_from_date and p_to_date;
    
    import_assignments_pkg.import_assignments(
      p_from_date => p_from_date,
      p_to_date   => p_to_date
    );
  end start_;
  
  function complete_ return boolean is
    l_cnt int;
  begin
    select count(1)
    into   l_cnt
    from   transform_pa_assignments t
    where  t.state = 'N';
    return l_cnt = 0;
  end;
  
begin
  while not complete_ loop
    dbms_lock.sleep(seconds => 120);
  end loop;
  log_pkg.enable_output;
  start_(
    p_from_date => to_date(20090101, 'yyyymmdd'),
    p_to_date   => to_date(20181201, 'yyyymmdd')
  );
exception
  when others then
    log_pkg.show_errors_all;
    raise;
end;
