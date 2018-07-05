select pof.*, pof.rowid
              from   pay_order_filters pof
              where  pof.filter_code = 'CONTRACT'
              and    pof.fk_pay_order = 23159079
/
select c.fk_contragent, pa.effective_date, pa.amount, paa.*
from   contracts c,
       pension_agreements pa,
       pension_agreement_addendums paa
where  c.fk_document = 13464073
and    pa.fk_contract = c.fk_document
and    paa.fk_pension_agreement = pa.fk_contract
/
