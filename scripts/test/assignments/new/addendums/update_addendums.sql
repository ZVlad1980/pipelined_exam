update (
select paa.canceled
from   pension_agreement_addendums paa,
       pension_agreements_v        pa
where  paa.canceled = 0
and    paa.alt_date_begin < pa.effective_date
and    pa.fk_contract = paa.fk_pension_agreement
) u
set u.canceled = 1
/
