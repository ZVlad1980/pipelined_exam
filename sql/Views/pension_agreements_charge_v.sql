create or replace view pension_agreements_charge_v as
  select pa.fk_contract,
         pa.fk_base_contract,
         pa.state,
         pa.fk_debit,
         pa.fk_credit,
         pa.fk_company,
         pa.fk_scheme,
         pa.fk_contragent,
         pa.effective_date,
         pa.expiration_date,
         pa.pa_amount,
         pa.deathdate,
         pa.last_pay_date
  from   pension_agreements_v pa
  where  1 = 1
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
--pension_agreements_v
