PL/SQL Developer Test script 3.0
15
-- Created on 18.07.2018 by V.ZHURAVOV 
declare 
begin
  --dbms_session.reset_package; return;
  -- Test statements here
  log_pkg.enable_output;
  import_assignments_pkg.create_accounts(
    p_from_date => to_date(19800101, 'yyyymmdd'),
    p_to_date   => sysdate
  );
exception
  when others then
    log_pkg.show_errors_all;
    raise;
end;
0
0
