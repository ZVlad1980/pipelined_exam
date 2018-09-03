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
         pa.pa_amount,
         pa.deathdate,
         pa.last_pay_date,
         pa.creation_date,
         case
           when not exists(
                  select 1
                  from   assignments asg
                  where  asg.fk_credit = pa.fk_credit
                ) then
             'Y'
           else
             'N'
         end is_first_pay
  from   pension_agreements_v pa
  where  1 = 1
  and    pa.state = 1
  and    pa.isarhv = 0
/
