--select count(1) from   pension_agreement_periods pap
select trunc(pap.effective_date, 'MM') payment_period,
       count(1) cnt,
       max(pap.fk_pension_agreement) fk_pension_agreement
from   pension_agreement_periods pap
group by trunc(pap.effective_date, 'MM')
order by payment_period
/
select *
from   pension_agreement_periods pap
where  pap.effective_date <> to_date('01.07.2018', 'dd.mm.yyyy')
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
