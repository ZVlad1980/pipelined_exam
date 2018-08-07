delete from pay_decisions          pd
where  (pd.id, trunc(pd.creation_date)) in (
         select tpp.fk_pay_decision,
                trunc(sysdate)
         from   transform_pa_portfolios tpp
         where  tpp.fk_pay_decision is not null
       )
/
delete pay_portfolios         pp
where  (pp.id, trunc(pp.creation_date)) in (
         select tpp.fk_pay_portfolios,
                trunc(sysdate)
         from   transform_pa_portfolio tpp
         where  tpp.fk_pay_portfolio is not null
       )
/

select count(1)
from   transform_pa_portfolios tpp,
       pay_decisions          pd
where  pd.id = tpp.fk_pay_decision
and    trunc(pd.creation_date) = trunc(sysdate)
/
select count(1)
from   transform_pa_portfolios tpp,
       pay_portfolios         pp
where  pp.id = tpp.fk_pay_portfolio
and    trunc(pp.creation_date) = trunc(sysdate)
/
