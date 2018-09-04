select *
from   pension_agreements_v pa
where  pa.fk_contract = &fk_pa --2763033
/
select *
from   pay_restrictions pr
where  pr.fk_doc_with_acct = &fk_pa
/
select pap.*, pap.rowid
from   pension_agreement_periods pap
where  pap.fk_pension_agreement = &fk_pa
/
select *
from   assignments asg
where  asg.fk_doc_with_acct = &fk_pa
and    asg.fk_asgmt_type = 2
order by asg.paydate
