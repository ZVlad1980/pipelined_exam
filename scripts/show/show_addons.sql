with w_addendums as (
  select paa.fk_pension_agreement,
         min(paa.alt_date_begin) alt_date_begin
  from   pension_agreement_addendums paa
  where  paa.is_new = 'Y'
  and    paa.canceled = 0
  group by paa.fk_pension_agreement
)
select *
from   w_addendums           paa,
       pension_agreements_v  pa,
       lateral(
         select pay_gfnpo_pkg.add_month$(trunc(pa.effective_date, 'MM'), level - 1) paydate
         from   dual
         connect by level <= 
           months_between(
             trunc(
               least(
                 coalesce(p.deathdate, sysdate),
                 coalesce(pa.expiration_date, sysdate),
                 to_date(20180430, 'yyyymmdd')
               ),
               'MM'
             ),
             trunc(paa.alt_date_begin, 'MM')
           ) + 1
        minus
         select trunc(a.paydate, 'MM') paydate
         from   assignments a
         where  a.fk_credit = co.fk_account
         and    a.fk_paycode in (5054, 5051)
       ) m
where  1=1
and    p.fk_contragent = 
and    pa.fk_contract = paa.fk_pension_agreement
