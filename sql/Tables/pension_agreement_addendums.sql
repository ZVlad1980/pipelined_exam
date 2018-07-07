alter table pension_agreement_addendums add is_new varchar2(1) default 'Y'
/
comment on column pension_agreement_addendums.is_new is 'Флаг новой/обновленной строки (для расчета доплат)';
/
create index pension_agrmnt_addendums_ix2 on pension_agreement_addendums(is_new)
/
