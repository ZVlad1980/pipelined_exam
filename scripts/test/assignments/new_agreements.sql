select count(1) from (
select pa.fk_contract,
       pa.fk_base_contract,
       pa.fk_debit,
       pa.fk_credit,
       pa.fk_company,
       pa.fk_scheme,
       pa.fk_contragent,
       pa.effective_date,
       pa.expiration_date,
       pa.pa_amount, 
       m.paydate,
       paa.amount charge_amount,
       last_day(least(pa.last_pay_date, to_date(20180630, 'yyyymmdd'))) last_pay_date --*/
from   pension_agreements_v pa, 
       lateral(
         select pay_gfnpo_pkg.add_month$(trunc(pa.effective_date, 'MM'), level - 1) paydate
         from   dual
         connect by level <= 
           months_between(
             trunc(
               least(
                 pa.last_pay_date,
                 to_date(20180630, 'yyyymmdd')
               ),
               'MM'
             ),
             trunc(pa.effective_date, 'MM')
           ) + 1
        minus
         select trunc(a.paydate, 'MM') paydate
         from   assignments a
         where  a.fk_credit = pa.fk_credit
         and    a.fk_paycode in (5000)
       ) m,
       lateral(
         select paa.fk_provacct, case when m.paydate = paa.from_date then paa.first_amount else paa.amount end amount
         from   pension_agreement_addendums_v paa
         where  paa.fk_pension_agreement = pa.fk_contract
         and    m.paydate between paa.from_date and paa.end_date
       ) paa --*/
where  1=1 
and    not exists(
         select 1
         from   pay_restrictions pr
         where  pr.fk_document_cancel is null
         and    m.paydate between pr.effective_date and nvl(pr.expiration_date, m.paydate)
         and    pr.fk_doc_with_acct = pa.fk_contract
       ) --*/
and    not exists (
         select 1
         from   registry_details rd,
                registries       rg,
                registry_types   rt
         where  rt.stop_pays = 1
         and    rt.id = rg.fk_registry_type
         and    rg.id = rd.fk_registry
         and    rd.fk_contract = pa.fk_base_contract
       )
and    pa.effective_date <= to_date(20180630, 'yyyymmdd')
/*and    pa.fk_contract in (
         select pof.filter_value
         from   pay_order_filters pof
         where  pof.filter_code = 'CONTRACT'
         and    pof.fk_pay_order = 23159079
       )*/
--order by paydate
) t --where t.paydate = to_date(20180601, 'yyyymmdd')
