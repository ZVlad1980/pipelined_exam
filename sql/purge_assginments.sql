delete from DEBT_WITHHOLDINGS
/
alter table DEBT_WITHHOLDINGS drop constraint DEBT_WH_ASSIGNMENT_FK
/
truncate table assignments
/
alter table DEBT_WITHHOLDINGS add constraint DEBT_WH_ASSIGNMENT_FK
foreign key (fk_debt_assignment)
references assignments(id)
/
delete from pay_orders
/
commit
/
