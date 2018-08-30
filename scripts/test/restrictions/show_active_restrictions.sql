/*
!!!
Надо доделать отмену ограничений с пересекающимися периодами!
Либо надо сравнить активные ограничения в pay_restrictions и fnd.sp_ogr_pv!
*/
select pr.* from (
select pr.*,
       max(pr.is_join)over(partition by pr.fk_doc_with_acct) max_is_join
from (
select pr.*,
       count(1)over(partition by pr.fk_doc_with_acct) cnt,
       case
         when lead(pr.effective_date)over(partition by pr.fk_doc_with_acct order by pr.id) < coalesce(pr.expiration_date, to_date(99991231, 'yyyymmdd'))
              and coalesce(lead(pr.expiration_date)over(partition by pr.fk_doc_with_acct order by pr.id), to_date(99991231, 'yyyymmdd')) > pr.effective_date
           then
             'Y'
       end is_join
       select count(1)
from   pay_restrictions pr
where  pr.fk_doc_with_acct in (
         select pa.fk_contract
         from   pension_agreements_v pa
       )
and    pr.fk_document_cancel is null
) pr where pr.cnt > 1
) pr where pr.max_is_join = 'Y'
order by pr.fk_doc_with_acct
/
select case when pr.fk_document_cancel is null then 'N' else 'Y' end cancelled, count(1)
from   pay_restrictions pr
group by case when pr.fk_document_cancel is null then 'N' else 'Y' end
/
