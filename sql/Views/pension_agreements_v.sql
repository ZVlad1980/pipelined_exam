create or replace view pension_agreements_v as
  select pa.fk_contract,
         pa.fk_base_contract,
         pa.state                                    state,
         bco.fk_account                              fk_debit,
         co.fk_account                               fk_credit,
         co.fk_company,
         co.fk_scheme,
         co.fk_contragent,
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
         contracts          co,
         contracts          bco,
         people             p
  where  1 = 1
  and    bco.fk_document = pa.fk_base_contract
  and    p.fk_contragent = co.fk_contragent
  and    co.fk_document = pa.fk_contract
  and    co.fk_company <> 1001
  and    co.fk_scheme <> 7
  and    co.fk_cntr_type = 6
  and    pa.state = 1
  and    not exists (select 1
          from   registry_details rd,
                 registries       rg,
                 registry_types   rt
          where  rt.stop_pays = 1
          and    rt.id = rg.fk_registry_type
          and    rg.id = rd.fk_registry
          and    rd.fk_contract = pa.fk_base_contract)
  and    pa.isarhv = 0
/
