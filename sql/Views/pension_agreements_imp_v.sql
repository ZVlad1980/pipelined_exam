create or replace view pension_agreements_imp_v as
  select pa.fk_base_contract, --временное представление для импорта данных из FND
         pa.fk_contract,
         pa.cntr_number,
         pa.state,
         pa.isarhv,
         pa.fk_debit,
         pa.fk_credit,
         pa.fk_pay_detail,
         pa.fk_company,
         pa.fk_scheme,
         pa.fk_contragent,
         pa.effective_date,
         pa.expiration_date,
         pa.pa_amount,
         pa.last_pay_date,
         pa.creation_date,
         pa.last_update,
         lead(pa.effective_date)over(partition by pa.fk_base_contract order by pa.effective_date) effective_date_next,
         row_number()over(partition by pa.fk_base_contract order by pa.effective_date) rn,
         count(1)over(partition by pa.fk_base_contract)                                cnt
  from   pension_agreements_v pa
/
