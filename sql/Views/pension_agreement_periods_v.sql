create or replace view pension_agreement_periods_v as
  select pap.fk_pension_agreement,
         pap.effective_date effective_calc_date,
         paa.fk_base_contract,
         paa.state,
         paa.period_code,
         paa.fk_debit,
         paa.fk_credit,
         paa.fk_company,
         paa.fk_scheme,
         paa.fk_contragent,
         paa.effective_date,
         paa.expiration_date,
         paa.pa_amount,
         paa.last_pay_date,
         paa.creation_date
  from   pension_agreement_periods   pap,
         pension_agreements_active_v paa
  where  paa.fk_contract = pap.fk_pension_agreement
/
