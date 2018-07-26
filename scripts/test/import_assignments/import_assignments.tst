PL/SQL Developer Test script 3.0
12
begin
  --dbms_session.reset_package; return;
  log_pkg.enable_output;
  import_assignments_pkg.import_assignments(
    p_from_date => to_date(19960201, 'yyyymmdd'),
    p_to_date   => to_date(19960228, 'yyyymmdd')
  );
exception
  when others then
    log_pkg.show_errors_all;
    raise;
end;
0
0
