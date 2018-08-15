create global temporary table assignments_tmp(
  fk_contract number(10),
  paydate     date
) on commit preserve rows
/
create unique index assignments_tmp_ux on assignments_tmp(fk_contract, paydate)
/
create table assignments_tmp2(
  fk_contract number(10),
  paydate     date,
  constraint assignments_tmp2_pk primary key (fk_contract, paydate)
) organization index
/
create unique index assignments_tmp2_ux on assignments_tmp2(fk_contract, paydate)
