create table accounts_balance(
  fk_account                number(10)
    constraint accounts_balance_pk
    primary key
    using index tablespace  GFNDINDX,
  fk_pension_agreement      number(10)
    constraint accounts_balance_uk
    unique
    using index tablespace  GFNDINDX
    not null,
  amount                    number(10, 2),
  update_date               date not null,
  constraint accounts_balance_fk_acc
    foreign key (fk_account)
    references accounts(id),
  constraint accounts_balance_fk_pa
    foreign key (fk_pension_agreement)
    references pension_agreements(fk_contract)
);
comment on table pension_agreement_periods is 'Остатки средств на ИПС';
