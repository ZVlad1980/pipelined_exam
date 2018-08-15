--Определение счетов ССПВ для 1, 5 и 6 схем:
with w_months as (
  select /*+ materialize*/ add_months(to_date(19950101, 'yyyymmdd'), level - 1) paydate
  from   dual
  connect by level < 283
)
select pa.fk_contract,
       pa.fk_base_contract,
       coalesce(paa.fk_provacct, pa.fk_debit) fk_debit,
       pa.fk_credit,
       pa.fk_company,
       pa.fk_scheme,
       pa.fk_contragent,
       pa.effective_date,
       pa.expiration_date,
       m.paydate,
       paa.amount charge_amount,
       last_day(least(pa.last_pay_date, to_date(20180630, 'yyyymmdd'))) last_pay_date
from   pension_agreements_charge_v   pa,
       w_months                      m,
       lateral(
         select paa.fk_provacct, case when m.paydate = paa.from_date then paa.first_amount else paa.amount end amount
         from   pension_agreement_addendums_v paa
         where  1=1
         and    m.paydate between paa.from_date and paa.end_date
         and    paa.fk_pension_agreement = pa.fk_contract
       )(+) paa
where  1 = 1
/*and    not exists (
         select 1
         from   assignments a
         where  trunc(a.paydate, 'MM') = m.paydate
         and    a.fk_paycode = 5000
         and    a.fk_credit = pa.fk_credit
         and    trunc(a.paydate, 'MM') < to_date(20180601, 'yyyymmdd')
       )
/*and    not exists (
          select 1
          from   pay_restrictions pr
          where  pr.fk_document_cancel is null
          and    m.paydate between pr.effective_date and
                 nvl(pr.expiration_date, m.paydate)
          and    pr.fk_doc_with_acct = pa.fk_contract
       )*/
and    m.paydate between trunc(pa.effective_date, 'MM')+1 and trunc(least(pa.last_pay_date, to_date(20180630, 'yyyymmdd')), 'MM')
and    pa.fk_contract = 2763533
and    pa.effective_date <= to_date(20180630, 'yyyymmdd')
/
