create or replace view pension_agreements_v as
  select bcn.fk_document                             fk_base_contract,
         cn.fk_document                              fk_contract,
         pa.state                                    state,
         pa.isarhv,
         bcn.fk_account                              fk_debit,
         cn.fk_account                               fk_credit,
         cn.fk_company,
         cn.fk_scheme,
         cn.fk_contragent,
         pa.effective_date,
         pa.expiration_date,
         pa.amount pa_amount,
         p.deathdate,
         last_day(
           least(
             coalesce(p.deathdate, sysdate),
             coalesce(pa.expiration_date, sysdate))
         )                                           last_pay_date
  from   pension_agreements pa,
         contracts          cn,
         contracts          bcn,
         people             p
  where  1 = 1
  and    bcn.fk_document = pa.fk_base_contract
  and    p.fk_contragent = bcn.fk_contragent
  and    pa.fk_contract = cn.fk_document
  and    cn.fk_scheme in (1, 2, 3, 4, 5, 6, 8)
  and    cn.fk_cntr_type = 6
/
--
