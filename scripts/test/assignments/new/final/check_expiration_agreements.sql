select pd.ssylka, pd.data_nach_vypl, pd.data_okon_vypl, pac.effective_date, pac.expiration_date, lspv.status_pen, pac.*
from   pension_agreements_active_v pac,
       transform_contragents       tc,
       fnd.sp_pen_dog              pd,
       fnd.sp_lspv                 lspv
where  1=1
and    lspv.ssylka_fl = pd.ssylka
and    coalesce(pd.data_okon_vypl, sysdate) <> coalesce(pac.expiration_date, sysdate)
and    pd.data_nach_vypl = pac.effective_date
and    pd.ssylka = tc.ssylka_fl
and    tc.fk_contragent = pac.fk_contragent
/
select pd.ssylka, pd.data_nach_vypl, pd.data_okon_vypl, pac.effective_date, pac.expiration_date, lspv.status_pen, pac.*
from   pension_agreements_active_v pac,
       transform_contragents       tc,
       fnd.sp_pen_dog              pd,
       fnd.sp_lspv                 lspv
where  1=1
and    lspv.status_pen not in ('и','п')
and    lspv.ssylka_fl = pd.ssylka
and    pd.data_nach_vypl = pac.effective_date
and    pd.ssylka = tc.ssylka_fl
and    tc.fk_contragent = pac.fk_contragent
/
