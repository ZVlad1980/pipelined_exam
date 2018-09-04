create or replace view pension_agreements_charge_v as
  select pa.fk_contract,
         pa.fk_base_contract,
         pa.state,
         pa.period_code,
         pa.fk_debit,
         pa.fk_credit,
         pa.fk_company,
         pa.fk_scheme,
         pa.fk_contragent,
         pa.effective_date,
         pa.expiration_date,
         coalesce(pap.effective_date, pa.effective_date) calc_effective_date,
         pa.pa_amount,
         pa.deathdate,
         pa.last_pay_date,
         pa.creation_date
  from   pension_agreements_v      pa,
         pension_agreement_periods pap
  where  1 = 1
  and    pap.fk_pension_agreement(+) = pa.fk_contract
  and    pa.state = 1
  and    pa.isarhv = 0
/
