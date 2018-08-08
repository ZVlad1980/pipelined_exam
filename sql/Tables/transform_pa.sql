create table transform_pa(
  ssylka_fl              number not null,
  date_nach_vypl         date not null,
  fk_base_contract       int,
  fk_contragent          int,
  ref_kodinsz            number,
  fk_contract            number,
  source_table           varchar2(32)  not null,
  data_arh               date
)
/
alter table transform_pa add constraint transform_pa_pk primary key (ssylka_fl, date_nach_vypl)
/
create unique index transform_pa_ux on transform_pa(source_table, ssylka_fl, data_arh)
/
create table transform_pa_portfolios(
  ssylka_fl         number,
  date_nach_vypl    date,
  source_table      varchar2(32),
  pd_creation_date  date,
  change_date       date,
  kod_izm           number(10),
  kod_doc           number(10),
  nom_izm           number(10),
  true_kod_izm      varchar2(1),
  fk_document       number(10),
  fk_pay_portfolio  number(10),
  fk_pay_decision   number(10)
)
/
alter table transform_pa_portfolios add constraint transform_pa_portfolios_pk primary key (ssylka_fl, date_nach_vypl)
/
--alter table transform_pa add fk_portfolio
create table transform_pa_accounts(
  account_type           varchar2(2), --Cr/Db
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
create unique index transform_pa_account_cntr_ux on transform_pa_accounts(account_type, fk_contract)
/
create table transform_pa_assignments(
  date_op                date         not null primary key,
  fk_pay_order           number(10)   not null,
  import_id              varchar2(14) not null,
  state                  varchar2(1)  default 'N' --New/Complete
  creation_date          date default sysdate,
) last_update_date       date default sysdate
/
