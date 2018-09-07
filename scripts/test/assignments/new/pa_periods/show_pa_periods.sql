--select count(1) from   pension_agreement_periods pap
select trunc(pap.effective_date, 'MM') payment_period,
       count(1) cnt,
       max(pap.fk_pension_agreement) fk_pension_agreement
from   pension_agreement_periods pap
group by trunc(pap.effective_date, 'MM')
order by payment_period
/
select months_between(t.last_pay_date, t.first_restriction_date) mb,
       t.*
from   (
select p.fk_contragent, 
       p.birthdate, 
       p.deathdate, 
       (
        select max(asg.paydate)
        from   assignments asg
        where  asg.fk_doc_with_acct = pap.fk_pension_agreement
        and    asg.fk_asgmt_type = 2
        and    asg.fk_paycode=5000
       ) last_pay_date,
       pap.*
from   pension_agreement_periods pap,
       contracts                 cn,
       people                    p
where  1=1
and    p.fk_contragent = cn.fk_contragent
and    cn.fk_document = pap.fk_pension_agreement
and    pap.effective_date >= to_date('01.01.2019','dd.mm.yyyy')
) t
/
select count(1)
from   pension_agreement_periods pap
where  pap.effective_date = to_date('01.07.2018', 'dd.mm.yyyy')
and    pap.first_restriction_date < pap.effective_date
/
select pap.payment_period,
       pap.cnt,
       pap.pct
from   (
          select pap.payment_period,
                 pap.cnt,
                 round(pap.cnt / sum(pap.cnt)over(), 2) * 100 pct
          from   (
                    select /*+ materialize*/
                           trunc(pap.effective_calc_date, 'MM') payment_period,
                           count(1) cnt
                    from   pension_agreement_periods_v pap
                    group by trunc(pap.effective_calc_date, 'MM')
                 ) pap
       ) pap
where pap.payment_period = to_date(20180701, 'yyyymmdd')
order by payment_period
