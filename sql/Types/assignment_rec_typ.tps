create or replace type assignment_rec_typ as object
(
  -- Author  : V.ZHURAVOV
  -- Created : 31.08.2018 13:47:46
  -- Purpose : calculate assignments, see pay_gfnpo_pkg
  
  -- Attributes
  fk_contract           number(10),
  fk_debit              number(10),
  fk_credit             number(10),
  fk_company            number(10),
  fk_scheme             number(5),
  fk_contragent         number(10),
  paydate               date,
  amount                number,
  paydays               number,
  addendum_from_date    date,
  last_pay_date         date,
  
  constructor function assignment_rec_typ return self as result
)
/
