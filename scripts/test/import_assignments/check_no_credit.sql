with w_contracts as (
select /*+ materialize*/
       tc.ssylka_fl, pa.*
from   pension_agreements_v  pa,
       transform_contragents tc
where  1=1
and    tc.fk_contract = pa.fk_base_contract
and    pa.fk_credit is null
)
select *
from   w_contracts c
where  exists(
         select 1
         from   fnd.vypl_pen_v vp
         where  vp.ssylka = c.ssylka_fl
         and    vp.data_nach_vypl = c.effective_date
       )
