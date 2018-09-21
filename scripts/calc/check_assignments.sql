/*--
create table assignments_201809_gf as --assignments_201809_gf as --23540831
select *
--delete
from   assignments asg
where  asg.fk_doc_with_action = 23908544
--truncate table pension_agreement_periods
select 'assignments' tbl, count(1) cnt, count(distinct asg.fk_doc_with_acct) cnt2
from   assignments asg
where  asg.fk_doc_with_action = 23908544
union all
select 'assignments_201809_fnd' tbl, count(1) cnt, count(distinct asg.fk_doc_with_acct) cnt2
from   assignments_201809_fnd asg
where  asg.fk_asgmt_type = 2
and    asg.fk_doc_with_action = 23540831
*/
/*
select *
from   assignments_201809_fnd  fasg
where  fasg.fk_doc_with_acct = 23540831
*/
--select * from assignments_201809_gf a where a.fk_doc_with_acct = 23292187
with w_asg as (
select distinct asg.fk_doc_with_acct
from   (
        select asg.fk_doc_with_acct, asg.paydate, round(asg.amount, 2) amount
        from   assignments_201809_fnd asg
        where  asg.fk_asgmt_type = 2
        minus
        select asg.fk_doc_with_acct, asg.paydate, round(asg.amount, 2) amount
        from   assignments_201809_gf asg
        where  asg.fk_doc_with_action = 23908544
       ) asg
       where asg.fk_doc_with_acct not in (
               23273375,
               23518353,
               23539988,
               23640265,
               23640295
             )
)
select asg2.fk_doc_with_acct,
       asg2.fk_debit,
       asg2.fk_asgmt_type,
       asg2.paydate,
       asg2.amount,
       asg2.paydays,
       asg.paydate new_pay_date,
       asg.amount new_amount,
       asg.paydays new_paydays ,
       b.amount balance_debit,
       pap.calc_date,
       pap.expiration_date,
       pap.period_code,
       pap.fk_scheme,
       pap.last_pay_date,
       pap.pa_amount,
       pap.fk_base_contract,
       pap.fk_contragent
from   w_asg w,
       assignments_201809_fnd       asg2,
       assignments_201809_gf        asg,
       pension_agreement_periods_v  pap,
       accounts_balance             b
where  1=1
and    b.fk_account(+) = pap.fk_debit
and    pap.fk_pension_agreement = asg2.fk_doc_with_acct
--and    coalesce(asg.amount, 0) = 0
--and    asg.amount <> asg2.amount
and    asg.paydate(+) = asg2.paydate
and    asg.fk_doc_with_acct(+) = asg2.fk_doc_with_acct
and    asg2.fk_doc_with_acct = w.fk_doc_with_acct
order by asg2.fk_doc_with_acct,
       asg2.paydate
/*w
select 'assignments' tbl, count(distinct asg.fk_doc_with_acct) cnt
from   assignments asg
where  asg.fk_doc_with_action = 23890256
union all
select 'assignments_201807' tbl, count(distinct asg2.fk_doc_with_acct) cnt
from   assignments_201807 asg2
where  asg2.fk_asgmt_type = 2
and    asg2.fk_doc_with_action = 23890256


select *
from   pension_agreements pa
where  pa.fk_contract = &contract
/
select *
from   accounts_balance b
where  b.fk_pension_agreement = &contract
*/
--15747729
