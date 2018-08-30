PL/SQL Developer Test script 3.0
9
begin
  --dbms_session.reset_package; return;
  log_pkg.enable_output;
  import_assignments_pkg.import_pa_addendums;
exception
  when others then
    log_pkg.show_errors_all;
    raise;
end;
0
0
