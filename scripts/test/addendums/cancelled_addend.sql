update (
select paa.id, paa.canceled, paa.canceled_new from (
select paa.id,
       paa.fk_pension_agreement,
       paa.serialno,
       paa.canceled,
       coalesce(
         (select min(paa2.serialno)
          from   pension_agreement_addendums paa2
          where  1=1
          and    paa2.serialno > paa.serialno
          and    paa2.alt_date_begin <= paa.alt_date_begin
          and    paa2.fk_pension_agreement = paa.fk_pension_agreement
         ),
         0
       ) canceled_new,
       paa.amount,
       paa.alt_date_begin,
       paa.alt_date_end,
       paa.creation_date
from   pension_agreement_addendums paa
where  paa.fk_pension_agreement in (
         select pa.fk_contract
         from   pension_agreements_v pa
       )
) paa where paa.canceled <> paa.canceled_new) paa
set paa.canceled = paa.canceled_new
/
select *
from   pension_agreement_addendums paa
where  paa.fk_pension_agreement = 2786176
