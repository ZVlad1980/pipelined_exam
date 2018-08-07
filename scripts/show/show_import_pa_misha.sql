select t.fk_contract, t.fk_base_contract, d.*--trunc(t.creation_date) creation_date, count(1)
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
insert into pay_decisions(
  fk_pay_portfolio,
  fk_decision_type,
  decision_number,
  decision_date,
  amount,
  pay_start,
  pay_stop,
  fk_pension_agreement,
  creation_date,
  fk_operator,
  fk_contract
) select tpp.fk_pay_portfolio,
         6,
         -1 * tpp.ssylka_fl,
         tpp.change_date,
         pa.pa_amount,
         pa.effective_date,
         pa.expiration_date,
         pa.fk_contract,
         sysdate,
         53,
         pa.fk_base_contract
  from   transform_pa_portfolio tpp,
         transform_pa           tpa,
         pension_agreements_v   pa
  where  1=1
  and    pa.fk_contract = tpa.fk_contract
  and    tpa.date_nach_vypl = tpp.date_nach_vypl
  and    tpa.ssylka_fl = tpp.ssylka_fl
  and    tpp.true_kod_izm in ('Y', 'N')
  and    tpp.fk_pay_portfolio is not null
  and    tpp.fk_pay_decision is null
/
