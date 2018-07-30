PL/SQL Developer Test script 3.0
30
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
  
begin
  
  --dbms_session.reset_package; return;
  log_pkg.enable_output;
  start_(
    p_from_date => to_date(19980101, 'yyyymmdd'),
    p_to_date   => to_date(20081231, 'yyyymmdd')
  );
exception
  when others then
    log_pkg.show_errors_all;
    raise;
end;
0
0
