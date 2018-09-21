select *
from   pension_agreement_periods_v pa
where  1=1--pa.effective_calc_date = to_date(20180901, 'yyyymmdd')
--and    pa.period_code > 1
and    pa.fk_pension_agreement = &fk_pa --23540831
/
select pa.*, rowid
from   pension_agreements pa
where  pa.fk_contract = &fk_pa --23540831
/
select cn.*, rowid
from   contracts cn
where  cn.fk_document = &fk_pa --23540831
/
select pap.*, rowid
from   pension_agreement_periods pap
where  pap.fk_pension_agreement = &fk_pa --2796396
/
select pr.*, rowid
from   pay_restrictions pr
where  pr.fk_doc_with_acct = &fk_pa --23540831
/
select paa.*, rowid
from   pension_agreement_addendums paa
where  paa.fk_pension_agreement = &fk_pa --23540831
/
/*
select *
from   assignments asg
where  asg.fk_doc_with_acct = 23540831
--*/
/
select b.*, rowid --176477,96
from   accounts_balance b
where  b.fk_account IN(
         select pa.fk_debit
         from   pension_agreements_v pa
         where  pa.fk_contract = &fk_pa
       )
/
/*
select *
from   pension_agreement_addendums_v paa
where  paa.fk_pension_agreement = &fk_pa --23540831
*/
