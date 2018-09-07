select count(1)
from   pension_agreements_fnd paf
union all
select count(1)
from   assignments asg
where  asg.fk_doc_with_action = 23855210
/
select count(distinct paf.fk_contract)
from   pension_agreements_fnd paf
union all
select count(distinct asg.fk_doc_with_acct)
from   assignments asg
where  asg.fk_doc_with_action = 23855210
/--170896
select paf.*, lspv.status_pen, cn.fk_scheme
from   pension_agreements_fnd paf,
       fnd.sp_lspv            lspv,
       contracts              cn
where  1=1
and    cn.fk_document = paf.fk_contract
and    lspv.ssylka_fl = paf.ssylka_fl
and    paf.fk_contract in (
         select paf.fk_contract
         from   pension_agreements_fnd paf
          minus
         select asg.fk_doc_with_acct
         from   assignments asg
         where  asg.fk_doc_with_action = 23855210
       )
/
select /*+ parallel(4)*/
       cast(null as varchar2(200)) comment_,
       paf.amount amount_fnd,
       asg.amount amount_gf,
       lspv.status_pen,
       cn.fk_scheme,
       paf.* --*/
from   pension_agreements_fnd paf,
       assignments            asg,
       fnd.sp_lspv            lspv,
       contracts              cn
where  1=1
and    cn.fk_document = paf.fk_contract
and    lspv.ssylka_fl = paf.ssylka_fl
and    asg.fk_doc_with_action = 23855210
and    round(asg.amount, 2) <> round(paf.amount, 2)
and    trunc(asg.paydate, 'MM') = trunc(paf.data_nachisl, 'MM')
and    asg.fk_doc_with_acct = paf.fk_contract
and    paf.fk_contract in (
         select count(distinct paf.fk_contract)
         from   (
            select paf.fk_contract, trunc(paf.data_nachisl, 'MM'), round(sum(paf.amount), 2) amount
            from   pension_agreements_fnd paf
            group by paf.fk_contract, trunc(paf.data_nachisl, 'MM')
            minus
            select asg.fk_doc_with_acct, trunc(asg.paydate, 'MM'), round(sum(asg.amount), 2) amount
            from   assignments asg
            where  asg.fk_doc_with_action = 23855210
            group by asg.fk_doc_with_acct, trunc(asg.paydate, 'MM')
           union all
            select asg.fk_doc_with_acct, trunc(asg.paydate, 'MM'), round(sum(asg.amount), 2) amount
            from   assignments asg
            where  asg.fk_doc_with_action = 23855210
            group by asg.fk_doc_with_acct, trunc(asg.paydate, 'MM')
            minus
            select paf.fk_contract, trunc(paf.data_nachisl, 'MM'), round(sum(paf.amount), 2) amount
            from   pension_agreements_fnd paf
            group by paf.fk_contract, trunc(paf.data_nachisl, 'MM')
         ) paf
       )
order by paf.fk_contract, paf.data_nachisl
/
select count(1)
from   (
            select paf.fk_contract, round(sum(paf.amount), 2) amount
            from   pension_agreements_fnd paf
            group by paf.fk_contract --, trunc(paf.data_nachisl, 'MM')
            intersect
            select asg.fk_doc_with_acct, round(sum(asg.amount), 2) amount
            from   assignments asg
            where  asg.fk_doc_with_action = 23855210
            group by asg.fk_doc_with_acct--, trunc(asg.paydate, 'MM')
       )
/
            select asg.fk_doc_with_acct
            from   assignments asg
            where  asg.fk_doc_with_action = 23855210
            group by asg.fk_doc_with_acct--, trunc(asg.paydate, 'MM')
            minus
            select paf.fk_contract
            from   pension_agreements_fnd paf
            group by paf.fk_contract --, trunc(paf.data_nachisl, 'MM')
/
select count(1)
from   pension_agreements_fnd paf
union all
select count(1)
from   assignments asg
where  asg.fk_doc_with_action = 23855210
/
--check amounts
create table assignments_diff as
select fnd.*
from   (
        select paf.fk_contract, round(coalesce(sum(vp.summa), 0), 2) amount,
               (
                select round(coalesce(sum(asg.amount), 0), 2) amount
                from   assignments asg
                where  asg.fk_doc_with_action = 23855397
                and    asg.fk_doc_with_acct = paf.fk_contract
                group by asg.fk_doc_with_acct
               ) amount_gf
        from   pension_agreements_fnd paf,
               fnd.vypl_pen           vp
        where  vp.data_op = paf.data_op
        and    vp.ssylka_fl = paf.ssylka_fl
        and    vp.data_nachisl = paf.data_nachisl
        group by paf.fk_contract
       ) fnd
where  fnd.amount <> fnd.amount_gf
/
select paf.fk_contract, round(sum(vp.summa), 2) amount
from   pension_agreements_fnd paf,
       fnd.vypl_pen           vp
where  vp.data_op = paf.data_op
and    vp.ssylka_fl = paf.ssylka_fl
and    vp.data_nachisl = paf.data_nachisl
group by paf.fk_contract
minus
select asg.fk_doc_with_acct, round(sum(asg.amount), 2)
from   assignments asg
where  asg.fk_doc_with_action = 23855397
group by asg.fk_doc_with_acct
/
select count(1)
from   assignments asg
where  asg.fk_doc_with_action = 23855397
and    asg.fk_doc_with_acct in (
         select paf.fk_contract
         from   pension_agreements_fnd paf
       )
/
select paf.*,
       case when exists(
           select 1
           from   people p,
                  contracts cn
           where  1=1
           and    p.deathdate is not null
           and    p.fk_contragent = cn.fk_contragent 
           and    cn.fk_document = paf.fk_contract
         ) then 'Y' else 'N' end is_dead
from   pension_agreements_fnd paf,
       assignments            asg
where  1=1
and    asg.id is null
and    asg.fk_doc_with_acct(+) = paf.fk_contract
and    asg.fk_doc_with_action(+) = 23855207
