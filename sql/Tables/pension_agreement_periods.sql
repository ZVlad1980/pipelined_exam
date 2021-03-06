create table pension_agreement_periods(
  fk_pension_agreement     number(10)
    constraint pension_agreement_periods_pk primary key,
  calc_date                date,
  check_date               date,
  creation_date            date default sysdate,
  pa_effective_date        date not null,
  is_disabled_pa           varchar2(1)
) organization index
 -- tablespace GFNDINDX
;
alter  table pension_agreement_periods add constraint 
  pension_agreement_periods_fk 
    foreign key (fk_pension_agreement)
    references pension_agreements
;
alter table pension_agreement_periods add pa_effective_date date
;
alter table pension_agreement_periods drop column  first_restriction_date
;
alter table pension_agreement_periods drop column  effective_date
;
alter table pension_agreement_periods add calc_date date not null
;
alter table pension_agreement_periods add check_date date not null
;
alter table pension_agreement_periods add is_disabled_pa varchar2(1)
;
--
comment on table pension_agreement_periods is 'Периоды оплаты по пенс.соглашеням';
comment on column pension_agreement_periods.calc_date is 'Дата первого не оплаченного периода';
comment on column pension_agreement_periods.check_date is 'Дата начала поиска пропущенных периодов';
comment on column pension_agreement_periods.pa_effective_date is 'Дата начала выплат соглашения (для контроля изменения)';
comment on column pension_agreement_periods.is_disabled_pa is 'Флаг инвалидного пенс.соглашения'
/
