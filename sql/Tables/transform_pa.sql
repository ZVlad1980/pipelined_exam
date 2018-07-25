create table transform_pa(
  ssylka_fl              number not null,
  date_nach_vypl         date not null,
  fk_base_contract       int,
  fk_contragent          int,
  ref_kodinsz            number,
  fk_contract            number,
  source_table           varchar2(32)  not null
)
/
alter table transform_pa add constraint transform_pa_pk primary key (ssylka_fl, date_nach_vypl)
/
--alter table transform_pa add fk_portfolio
create table transform_pa_accounts(
  account_type           varchar2(2), --Cr/Dt
  ssylka_fl              number(10),
  pa_effective_date      date,
  fk_contragent          number(10),
  fk_base_contract       number(10),
  fk_contract            number(10),
  cntr_number            number(10),
  fk_scheme              number(10),
  pa_expiration_date     date,
  fk_account             number(10),
  source_table           varchar2(32)  not null
)
/
alter table transform_pa_accounts add constraint transform_pa_accounts_pk primary key (account_type, ssylka_fl, pa_effective_date)
/
create unique index transform_pa_account_cntr_ux on transform_pa_accounts(fk_contract)
/
