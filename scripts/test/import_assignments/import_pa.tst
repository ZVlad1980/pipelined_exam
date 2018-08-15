PL/SQL Developer Test script 3.0
29
-- Created on 18.07.2018 by V.ZHURAVOV 
declare 
begin
  --dbms_session.reset_package; return;
  -- Test statements here
  log_pkg.enable_output;
  
  import_assignments_pkg.import_pension_agreements(
    p_from_date => to_date(19960101, 'yyyymmdd'),
    p_to_date   => to_date(20180630, 'yyyymmdd')
  );
  
  import_assignments_pkg.import_pa_addendums;
  
  import_assignments_pkg.create_accounts(
    p_from_date => to_date(19960101, 'yyyymmdd'),
    p_to_date   => to_date(20180630, 'yyyymmdd')
  );
  
  import_assignments_pkg.import_assignments(
    p_from_date => to_date(19960101, 'yyyymmdd'),
    p_to_date   => to_date(20180630, 'yyyymmdd')
  );
  
exception
  when others then
    log_pkg.show_errors_all;
    raise;
end;
0
0
