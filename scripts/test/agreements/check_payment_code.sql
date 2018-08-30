select pd.id_period_payment, pa.period_code, count(1) cnt, max(pd.ssylka), max(pa.fk_contract) --pd.ssylka, pd.id_period_payment, pa.period_code, pa.*
from   pension_agreements_v  pa,
       transform_contragents tc,
       fnd.sp_pen_dog_v      pd
where  1=1
and    pa.period_code <> coalesce(pd.id_period_payment, 1)
and    pd.data_nach_vypl = pa.effective_date
and    pd.ssylka = tc.ssylka_fl
and    tc.fk_contract = pa.fk_base_contract
group by pd.id_period_payment, pa.period_code
/
select pa.fk_contract, coalesce(pd.id_period_payment, 1) period_code
from   pension_agreements_v  pa,
       transform_contragents tc,
       fnd.sp_pen_dog_v      pd
where  1=1
and    pa.period_code <> coalesce(pd.id_period_payment, 1)
and    pd.data_nach_vypl = pa.effective_date
and    pd.ssylka = tc.ssylka_fl
and    tc.fk_contract = pa.fk_base_contract
