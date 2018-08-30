insert into assignments_tmp2(
  fk_contract,
  paydate
) with w_months as (
    select /*+ materialize*/ add_months(to_date(19950101, 'yyyymmdd'), level - 1) paydate
    from   dual
    connect by level < months_between(to_date(20180630, 'yyyymmdd'), to_date(19950101, 'yyyymmdd')) + 1
  )
  select pa.fk_contract,
         m.paydate
  from   pension_agreements_charge_v   pa,
         w_months                      m
  where  1=1
  and    not exists (
            select 1
            from   pay_restrictions pr
            where  pr.fk_document_cancel is null
            and    m.paydate between pr.effective_date and
                   nvl(pr.expiration_date, m.paydate)
            and    pr.fk_doc_with_acct = pa.fk_contract
         )
  and    not exists (
           select 1
           from   assignments a
           where  trunc(a.paydate, 'MM') = m.paydate
           and    a.fk_paycode = 5000
           and    a.fk_credit = pa.fk_credit
         )
  and    m.paydate between last_day(pa.effective_date) + 1 and trunc(least(pa.last_pay_date, to_date(20180630, 'yyyymmdd')), 'MM')  --*/
  --and    pa.fk_contract = 3811044
  and    pa.effective_date <= to_date(20180630, 'yyyymmdd')
/
commit
/
--duration: 34 min
