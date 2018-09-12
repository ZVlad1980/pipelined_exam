create table accounts_balance(
  fk_account                number(10)
    constraint accounts_balance_pk
    primary key,
  transfer_date        date,
  amount                    number(10, 2),
  update_date               date not null,
  constraint accounts_balance_fk_acc
    foreign key (fk_account)
    references accounts(id)
) organization index;
comment on table accounts_balance is 'Остатки средств на ИПС';
comment on column accounts_balance.transfer_date is 'Дата перевода средств с ИПС на ССПВ (5 схема)'
/
