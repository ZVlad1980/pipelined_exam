create table pension_agreement_periods(
  fk_pension_agreement     number(10)
    constraint pension_agreement_periods_pk primary key,
  effective_date           date,
  first_restriction_date   date,
  creation_date            date default sysdate
) organization index
 -- tablespace GFNDINDX
/
