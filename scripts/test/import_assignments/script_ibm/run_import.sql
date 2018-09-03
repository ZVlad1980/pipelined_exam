connect gazfond/"mju7ygvfr$"@fonddb
select 'Connect to ' || application_title app_title from app_settings where id=0;

prompt Purge ASSIGNMENTS
delete from DEBT_WITHHOLDINGS;
alter table DEBT_WITHHOLDINGS drop constraint DEBT_WH_ASSIGNMENT_FK;
truncate table assignments;
drop index ASGMT_DOC_ACCOUNT_IDX;
drop index ASSIGNMENT_DIRECTION_IDX;
drop index ASGMT_ISAUTO_IDX;
drop index ASGMT_ISCANCEL_IDX;
drop index ASMGT_ISEXISTS_IDX;
drop index ASGMT_STATE_IDX;
create index ASGMT_STATE_IDX on assignments(case ASGMT_STATE when 1 then null else ASGMT_STATE end);
alter table DEBT_WITHHOLDINGS add constraint DEBT_WH_ASSIGNMENT_FK foreign key (fk_debt_assignment) references assignments(id);
delete from pay_orders;
commit;
prompt Purge ASSIGNMENTS complete

begin
  dbms_output.enable(100000);
  -- Test statements here
  log_pkg.enable_output;
  import_assignments_pkg.import_assignments(
    p_from_date => to_date(19950101, 'yyyymmdd'),
    p_to_date   => to_date(20081231, 'yyyymmdd')
  ); --*/

exception
  when others then
    log_pkg.show_errors_all;
    raise;
end;
/
exit
