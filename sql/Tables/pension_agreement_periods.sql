create table pension_agreement_periods(
  fk_pension_agreement     number(10)
    constraint pension_agreement_periods_pk primary key,
  effective_date           date,
  first_restriction_date   date,
  balance                  number(10, 2),
  creation_date            date default sysdate
) organization index
 -- tablespace GFNDINDX
/
alter  table pension_agreement_periods add constraint 
  pension_agreement_periods_fk 
    foreign key (fk_pension_agreement)
    references pension_agreements
/
alter table pension_agreement_periods drop column expiration_date;
alter table pension_agreement_periods drop column is_ips ;
alter table pension_agreement_periods drop column balance ;
--
comment on table pension_agreement_periods is 'Периоды оплаты по пенс.соглашеням';
comment on column pension_agreement_periods.effective_date is 'Дата первого не оплаченного периода';
comment on column pension_agreement_periods.first_restriction_date is 'Дата начала первого активного ограничения';
