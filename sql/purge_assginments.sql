delete from DEBT_WITHHOLDINGS;
alter table DEBT_WITHHOLDINGS drop constraint DEBT_WH_ASSIGNMENT_FK;
truncate table assignments;
drop index ASGMT_DOC_ACCOUNT_IDX;
drop index ASSIGNMENT_DIRECTION_IDX;
drop index ASGMT_ISAUTO_IDX;
drop index ASGMT_ISCANCEL_IDX;
drop index ASMGT_ISEXISTS_IDX;
drop index ASGMT_STATE_IDX;
create index ASGMT_STATE_IDX on assignments(case ASGMT_STATE when 1 then null else ASGMT_STATE end) tablespace GFNDINDX;
alter table DEBT_WITHHOLDINGS add constraint DEBT_WH_ASSIGNMENT_FK foreign key (fk_debt_assignment) references assignments(id);
delete from pay_orders;
commit;
/
select *
from   user_constraints d
where  d.r_owner = 'GAZFOND_PN'
and    d.r_constraint_name = 'ASSIGNMENT_PK'
and    d.
/
