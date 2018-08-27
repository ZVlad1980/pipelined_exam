select count(1) --168963
from   fnd.sp_pen_dog pd,
       fnd.sp_lspv    lspv
where  1=1
and    pd.shema_dog in (1,2,3,4,5,6,8)
and    pd.ssylka = lspv.ssylka_fl
and    lspv.status_pen in ('п','и')
/
select case when pa.state = 1 and pa.isarhv = 0 then 'Active' else 'Cancel' end,
       count(1) --168885 + 78
from   fnd.sp_pen_dog pd,
       fnd.sp_lspv    lspv,
       transform_contragents tc,
       pension_agreements_v pa
where  1=1
and    pa.effective_date = pd.data_nach_vypl
and    pa.fk_base_contract = tc.fk_contract
and    tc.ssylka_fl = pd.ssylka
and    pd.shema_dog in (1,2,3,4,5,6,8)
and    pd.ssylka = lspv.ssylka_fl
and    lspv.status_pen in ('п','и')
group by rollup(case when pa.state = 1 and pa.isarhv = 0 then 'Active' else 'Cancel' end)
/--168513
select count(1) --168886
from   pension_agreements_v pa
where  pa.state = 1
and    pa.isarhv = 0
