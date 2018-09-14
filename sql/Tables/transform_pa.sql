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
alter table transform_pa add constraint transform_pa_pk primary key (ssylka_fl, date_nach_vypl) using index tablespace GFNDINDX
/
create unique index transform_pa_ux on transform_pa(source_table, ssylka_fl, data_arh) tablespace GFNDINDX
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
alter table transform_pa_portfolios add constraint transform_pa_portfolios_pk primary key (ssylka_fl, date_nach_vypl) using index tablespace GFNDINDX
/
create table transform_pa_restrictions(
  import_id              varchar2(14) not null,
  ssylka                 number(10)   not null,
  fk_contragent          number(10),
  fk_contract            number(10),
  kod_ogr_pv             number(1)    not null,
  primech                varchar2(255) ,
  nach_deistv            date         not null,
  okon_deistv            date                 ,
  fnd_nach_deistv        date         not null,
  fnd_okon_deistv        date                 ,
  fk_pay_restriction     number(10),
  is_cancel              varchar2(1),
  cnt                    number(2),
  rn                     number(2)
)
/
create index transform_pa_rest_ux on transform_pa_restrictions(import_id, ssylka, kod_ogr_pv, nach_deistv, fk_contract) tablespace GFNDINDX
/
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
alter table transform_pa_accounts add constraint transform_pa_accounts_pk primary key (account_type, ssylka_fl, pa_effective_date) using index tablespace GFNDINDX
/
create unique index transform_pa_account_cntr_ux on transform_pa_accounts(account_type, fk_contract) tablespace GFNDINDX
/
create table transform_po(
  ssylka_doc     number(10,0)
    constraint transform_po_pk primary key
    using index tablespace gfndindx,
  flag_usage     number(1),
  rn             number(2),
  max_half_month number(1),
  operation_date date, 
  payment_period date, 
  half_month     number(1),
  fk_document    number(10)
    constraint transform_po_unq unique
    using index tablespace gfndindx
)
/
comment on table transform_po is 'Связь FND.REER_DOC_NGPF и PAY_ORDERS';
comment on column transform_po.ssylka_doc is 'FND.REER_DOC_NGPF.SSYLKA, только для FLAG_USAGE=2';
comment on column transform_po.flag_usage is '1-обычный PO, 2-PO исключение';
comment on column transform_po.rn             is 'Порядковый номер PO в периоде по дате операции';
comment on column transform_po.max_half_month is 'Максимальный номер полумесяца (1 или 2)';
comment on column transform_po.operation_date is 'Дата операции для PAY_ORDERS';
comment on column transform_po.payment_period is 'Период оплаты для PAY_ORDERS';
comment on column transform_po.half_month     is 'Полумесяц, для периода оплаты';
comment on column transform_po.fk_document    is 'ID PAY_ORDER';
/
--drop table transform_pa_assignments
create table transform_pa_assignments(
  date_op                date         not null,
  ssylka_doc             number(10),
  fk_pay_order           number(10)   not null,
  import_id              varchar2(14) not null,
  state                  varchar2(1)  default 'N', --New/Complete
  creation_date          date,
  last_update_date       date,
  constraint transform_pa_assign_uk 
    unique (date_op, ssylka_doc)
      using index tablespace GFNDINDX
)
/
comment on table transform_pa_assignments is 'Связь FND.VYPL_PEN и PAY_ORDERS';
comment on column transform_pa_assignments.date_op is 'FND.VYPL_PEN.DATA_OP';
comment on column transform_pa_assignments.ssylka_doc       is 'TRANSFORM_PO.SSYKLA_DOC';
comment on column transform_pa_assignments.fk_pay_order     is 'ID PAY_ORDER';
comment on column transform_pa_assignments.import_id        is 'ID импорта';
comment on column transform_pa_assignments.state            is 'Состояние: (N)ew/(W)ork/(C)omplete';
comment on column transform_pa_assignments.creation_date    is 'Дата создания';
comment on column transform_pa_assignments.last_update_date is 'Дата последнего обновления';
/
