create table pension_agreement_periods(
  fk_pension_agreement     number(10)
    constraint pension_agreement_periods_pk primary key,
  effective_date           date,
  first_restriction_date   date,
  creation_date            date default sysdate,
  pa_effective_date        date not null
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
--
comment on table pension_agreement_periods is 'Периоды оплаты по пенс.соглашеням';
comment on column pension_agreement_periods.effective_date is 'Дата первого не оплаченного периода';
comment on column pension_agreement_periods.first_restriction_date is 'Дата начала первого активного ограничения'
comment on column pension_agreement_periods.pa_effective_date is 'Дата начала выплат соглашения (для контроля изменения)';
/
