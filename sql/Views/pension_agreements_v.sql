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
         p.deathdate,
         last_day(
           least(
             coalesce(p.deathdate, to_date(99991231, 'yyyymmdd')),
             coalesce(pa.expiration_date, to_date(99991231, 'yyyymmdd')))
         )                                           last_pay_date,
         pa.creation_date,
         pa.last_update
  from   pension_agreements pa,
         contracts          cn,
         contracts          bcn,
         people             p
  where  1 = 1
  and    p.fk_contragent = bcn.fk_contragent
  and    bcn.fk_document = pa.fk_base_contract
  and    pa.fk_contract = cn.fk_document
  and    cn.fk_scheme in (1, 2, 3, 4, 5, 6, 8)
  and    cn.fk_cntr_type = 6
/
