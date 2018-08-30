update pension_agreements pa
set    pa.state = 1,
       pa.isarhv = 0
where  pa.fk_contract in (
        select pa.fk_contract
        from   fnd.sp_pen_dog pd,
               fnd.sp_lspv    lspv,
               transform_contragents tc,
               pension_agreements_v pa
        where  1=1
        and    not(pa.state = 1 and pa.isarhv = 0)
        and    pa.effective_date = pd.data_nach_vypl
        and    pa.fk_base_contract = tc.fk_contract
        and    tc.ssylka_fl = pd.ssylka
        and    pd.shema_dog in (1,2,3,4,5,6,8)
        and    pd.ssylka = lspv.ssylka_fl
        and    lspv.status_pen in ('п','и')
       )
/
update pension_agreements pa
set    pa.state = 2
where  1=1
and    (pa.fk_base_contract, pa.effective_date) in (
         select pa.fk_base_contract, pa.effective_date
         from   pension_agreements_v pa
         where  pa.state = 1
         and    pa.isarhv = 0 --171468 - 168513
        minus
         select tc.fk_contract, pd.data_nach_vypl
         from   fnd.sp_pen_dog pd,
                fnd.sp_lspv    lspv,
                transform_contragents tc
         where  1=1
         and    tc.ssylka_fl = pd.ssylka
         and    pd.shema_dog in (1,2,3,4,5,6,8)
         and    pd.ssylka = lspv.ssylka_fl
         and    lspv.status_pen in ('п','и')
       )
