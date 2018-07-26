select t.fk_contract, p.*--trunc(t.creation_date) creation_date, count(1)
from   pension_agreements t,
       contracts          cn,
       pay_decisions      d,
       pay_portfolios     p
where  1=1
and    p.id = d.fk_pay_portfolio
and    d.fk_pension_agreement = t.fk_contract
and    cn.fk_document = t.fk_contract
and    cn.fk_scheme in (1,2,3,4,5,6,8)
and    t.creation_date = to_date('17.05.2018 17:25:29', 'dd.mm.yyyy hh24:mi:ss')--) = to_date('17.05.2018', 'dd.mm.yyyy') --between to_date(20180501, 'yyyymmdd') and to_date(20180531, 'yyyymmdd')
--into pension_agreements(fk_contract, effective_date, expiration_date, amount, delta_pen, fk_base_contract, period_code, years, state, isarhv)
/
