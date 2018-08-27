select case when exists(
         select 1
         from   pay_decisions        pd,
                pension_agreements    pa,
                transform_contragents tc,
                fnd.sp_invalid_v      inv
         where  1=1
         and    inv.ssylka_fl = tc.ssylka_fl
         and    tc.fk_contract = pa.fk_base_contract
         and    pa.fk_contract = pd.fk_pension_agreement
         and    pd.fk_pay_portfolio = pp.id
         
       ) then 5 else 4 end, pp.*
from   pay_portfolios pp
where  pp.id in (
         select pd.fk_pay_portfolio
          from   pension_agreements_v pa,
                 pay_decisions        pd
          where  1 = 1
          and    pd.fk_pension_agreement = pa.fk_contract
       )
and    pp.fk_app_type = 2
/
update pay_portfolios pp
set    pp.fk_app_type = case when exists(
         select 1
         from   pay_decisions        pd,
                pension_agreements    pa,
                transform_contragents tc,
                fnd.sp_invalid_v      inv
         where  1=1
         and    inv.ssylka_fl = tc.ssylka_fl
         and    tc.fk_contract = pa.fk_base_contract
         and    pa.fk_contract = pd.fk_pension_agreement
         and    pd.fk_pay_portfolio = pp.id
         
       ) then 5 else 4 end
where  pp.id in (
         select pd.fk_pay_portfolio
          from   pension_agreements_v pa,
                 pay_decisions        pd
          where  1 = 1
          and    pd.fk_pension_agreement = pa.fk_contract
       )
and    pp.fk_app_type = 2
