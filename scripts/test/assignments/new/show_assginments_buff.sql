with w_months(month_date, last_month_date) as (
  select /*+ materialize*/
         m.month_date, last_day(m.month_date)
  from   (
              select add_months(to_date(20080101, 'yyyymmdd'), level - 1) month_date
              from   dual
              connect by level < 133
         ) m
  where m.month_date < to_date(20180701, 'yyyymmdd')
) --*/
select ab.last_pay_date, pr.*
from   assignments_buff ab,
       pay_restrictions pr
where  1=1
and    exists(
         select 1
         from   w_months    m
         where  1=1
         and    not exists (
                  select 1
                  from   assignments asg
                  where  1=1 /*and   asg.paydate between m.month_date and m.last_month_date
                  and    asg.fk_credit = ab.fk_credit --*/
                  and    asg.serv_date between m.month_date and m.last_month_date
                  and    asg.serv_doc = ab.fk_contract
                  and    asg.fk_doc_with_acct = ab.fk_contract
                )
         and    m.month_date between trunc(pr.effective_date, 'MM') and nvl(last_day(pr.expiration_date), ab.last_pay_date)
       )
and    pr.fk_document_cancel is not null
and    pr.effective_date <> coalesce(pr.expiration_date, pr.effective_date - 1)
and    pr.effective_date < ab.last_pay_date
and    pr.fk_doc_with_acct = ab.fk_contract
