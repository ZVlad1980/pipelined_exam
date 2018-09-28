alter table pension_agreements add date_pension_age date;
alter table pension_agreements add constraint pension_agreements_dpa_chk check (date_pension_age = trunc(date_pension_age, 'MM'));
comment on column pension_agreements.date_pension_age is 'Дата пенсии по возрасту';
/
