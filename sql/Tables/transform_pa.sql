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
