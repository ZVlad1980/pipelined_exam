PL/SQL Developer Test script 3.0
12
-- Created on 03.09.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
begin
  --dbms_session.reset_package; return;
  -- Test statements here
  log_pkg.enable_output;
  pay_gfnpo_pkg.update_pa_periods(
    to_date(20180701, 'yyyymmdd')
  );
  dbms_stats.gather_table_stats(user, upper('pension_agreement_periods'), degree => 4, cascade => true);
end;
0
0
