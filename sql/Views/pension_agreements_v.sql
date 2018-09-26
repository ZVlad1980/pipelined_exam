create or replace view pension_agreements_v as
  select bcn.fk_document                             fk_base_contract,
         cn.fk_document                              fk_contract,
         cn.cntr_number                              cntr_number,
         pa.state                                    state,
         pa.period_code                              period_code,
         pa.isarhv,
         bcn.fk_account                              fk_debit,
         cn.fk_account                               fk_credit,
         pa.fk_pay_detail,
         cn.fk_company,
         cn.fk_scheme,
         cn.fk_contragent,
         pa.effective_date,
         pa.expiration_date,
         pa.amount pa_amount,
         coalesce(pa.expiration_date, to_date(99991231, 'yyyymmdd')) last_pay_date,
         pa.creation_date,
         pa.last_update,
         bcn.fk_cntr_type                            fk_base_cntr_type,
         bcn.fk_scheme                               fk_base_scheme,
         pa.date_pension_age
  from   pension_agreements pa,
         contracts          cn,
         contracts          bcn
  where  1 = 1
  and    bcn.fk_document = pa.fk_base_contract
  and    pa.fk_contract = cn.fk_document
  and    bcn.fk_scheme in (1, 2, 3, 4, 5, 6, 8)
  and    cn.fk_scheme in (1, 2, 3, 4, 5, 6, 8)
  and    cn.fk_cntr_type = 6
/
