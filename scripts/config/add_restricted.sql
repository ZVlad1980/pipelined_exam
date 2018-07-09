insert into pay_restrictions(
  id,
  fk_doc_with_action,
  fk_document_cancel,
  fk_doc_with_acct,
  effective_date,
  expiration_date,
  creation_date
) select pay_restriction_seq.nextval,
         0,
         null,
         pa.fk_contract, 
         pa.effective_date,
         to_date(20180531, 'yyyymmdd'),
         sysdate
  from   pension_agreements_v pa
  where  1=1
  and    pa.effective_date < to_date(20180630, 'yyyymmdd')
/
select *
from   pay_restrictions pr
where  pr.fk_document_cancel is null
and    m.paydate between pr.effective_date and nvl(pr.expiration_date, m.paydate)
and    pr.fk_doc_with_acct = pa.fk_contract
/
delete from pay_restrictions pr
where  pr.fk_doc_with_acct in (
  select pa.fk_contract
  from   pension_agreements_v pa
  where  1=1
  and    pa.effective_date < to_date(20180630, 'yyyymmdd')
)
and   pr.creation_date > trunc(sysdate)
