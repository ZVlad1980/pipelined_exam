select pa.fk_contract,
             pa.fk_base_contract,
             coalesce(paa.fk_provacct, bco.fk_account)   fk_debit,
             co.fk_account    fk_credit,
             co.fk_company,
             co.fk_scheme,
             co.fk_contragent,
             pa.effective_date,
             pa.expiration_date,
             pa.amount pa_amount, 
             m.paydate,
             paa.amount charge_amount,
             last_day(coalesce(p.deathdate, to_date(20180430, 'yyyymmdd'))) last_pay_date
      from   contracts          co,
             pension_agreements pa,
             contracts          bco,
             people             p , 
             lateral(
               select pay_gfnpo_pkg.add_month$(trunc(pa.effective_date, 'MM'), level - 1) paydate
               from   dual
               connect by level <= months_between(trunc(to_date(20180430, 'yyyymmdd'), 'MM'), trunc(pa.effective_date, 'MM')) + 1
              minus
               select trunc(a.paydate, 'MM') paydate
               from   assignments a
               where  a.fk_credit = co.fk_account
               and    a.fk_paycode = 5054
             ) m,
             lateral(
               select paa.fk_provacct, case when m.paydate = paa.from_date then paa.first_amount else paa.amount end amount
               from   pension_agreement_addendums_v paa
               where  paa.fk_pension_agreement = pa.fk_contract
               and    m.paydate between paa.from_date and paa.end_date
             )(+) paa
      where  1=1 
      and    not exists(
               select 1
               from   pay_restrictions pr
               where  pr.fk_document_cancel is null
               and    to_date(20170501, 'yyyymmdd') between pr.effective_date and  nvl(pr.expiration_date, m.paydate)
               and    pr.fk_doc_with_acct = co.fk_document
             )
      and    bco.fk_document = pa.fk_base_contract
      and    p.fk_contragent = co.fk_contragent 
      and    co.fk_document = pa.fk_contract
      and    co.fk_company <> 1001
      and    co.fk_scheme <>  7
      and    co.fk_cntr_type = 6
      and    pa.state = 1
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
      and    pa.effective_date <= to_date(20180430, 'yyyymmdd')
      and    pa.isarhv = 0
and pa.fk_contract in (
           select pof.filter_value
           from   pay_order_filters pof
           where  pof.filter_code = 'CONTRACT'
           and    pof.fk_pay_order = 23159079)--*/
/
/*loop
dbms_output.put_line(i.effective_date);
end loop;
end;
*/
/*
select a.*, a.rowid
from   assignments a
where  a.fk_credit = 3387759
and    a.fk_paycode = 5054
order by a.paydate
--11978971  22958657  13464073  10042 3387759 2 1612378 01.03.2018  36919,8 0 0 5054  31  1   0         0 0 0 13464073  01.03.2018  02.07.2018 11:34:15   1

*/
