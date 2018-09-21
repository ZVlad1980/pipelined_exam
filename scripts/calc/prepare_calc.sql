begin
  import_assignments_pkg.synchronize(
    p_from_date => to_date(20180601, 'yyyymmdd'),
    p_to_date   => to_date(&date_op, 'yyyymmdd')
  );
end;
/
begin
  execute immediate 'drop table pension_agreements_fnd';
exception
  when others then
    null;
end;
/
create table pension_agreements_fnd as
  select pa.fk_contract,
         vp.data_nachisl,
         vp.ssylka_fl,
         vp.data_op,
         vp.tip_vypl,
         sum(vp.summa) amount
  from   fnd.vypl_pen_imp_v    vp,
         transform_contragents tc,
         pension_agreements_v  pa
  where  1=1
  and    pa.effective_date = vp.data_nach_vypl
  and    pa.fk_base_contract = tc.fk_contract
  and    tc.ssylka_fl = vp.ssylka_fl
  and    vp.summa <> 0
  and    vp.data_op = to_date(&date_op, 'yyyymmdd')
  group by pa.fk_contract, vp.data_nachisl, vp.ssylka_fl, vp.data_op, vp.tip_vypl
;
update pension_agreements pa
set    pa.state = 2
where  1=1
and    pa.fk_contract in (
         select pav.fk_contract
         from   pension_agreements_v pav
         where  pav.state = 1
         and    pav.isarhv = 0
         minus
         select paf.fk_contract
         from   pension_agreements_fnd paf
       )
;
update pension_agreements pa
set    pa.state = 1,
       pa.isarhv = 0
where  1=1
and    pa.fk_contract in (
         select paf.fk_contract
         from   pension_agreements_fnd paf
         minus
         select pav.fk_contract
         from   pension_agreements_v pav
         where  pav.state = 1
         and    pav.isarhv = 0
       )
;
update pay_restrictions       pru
set    pru.fk_document_cancel = 0
where  pru.id in (
select pr.id
from   pension_agreements_fnd paf,
       pay_restrictions       pr
where  1=1
and    paf.data_nachisl between pr.effective_date and coalesce(pr.expiration_date, paf.data_nachisl)
and    pr.fk_document_cancel is null
and    pr.fk_doc_with_acct = paf.fk_contract
)
;
update pension_agreement_addendums paa
set    paa.canceled = 0
where  (paa.fk_pension_agreement, paa.canceled) in (
select paa.fk_pension_agreement, paa.serialno
from   pension_agreement_addendums paa
where  1=1
and    paa.creation_date > to_date(&actual_date, 'yyyymmdd') - 4 --расчет выполняется раньше даты операции банка
and    paa.fk_pension_agreement in (
         select paf.fk_contract
         from   pension_agreements_fnd paf 
       )
)
and    paa.canceled > 0
;
update pension_agreement_addendums paa
set    paa.canceled = 1
where  paa.creation_date > to_date(&actual_date, 'yyyymmdd') - 4--расчет выполняется раньше даты операции банка
and    paa.fk_pension_agreement in (
         select paf.fk_contract
         from   pension_agreements_fnd paf
       )
and    paa.serialno > 0
;
--check agreements wo addendums
select pa.*
from   pension_agreements_fnd paf,
       pension_agreements_v   pa
where  1=1
and    pa.fk_contract = paf.fk_contract
and    not exists (
         select 1
         from   pension_agreement_addendums paa
         where  paa.fk_pension_agreement = paf.fk_contract
       )
/
