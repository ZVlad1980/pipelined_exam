with w_months(paydate) as (
  select /*+ materialize*/ add_months(to_date(20160101, 'yyyymmdd'), level - 1) paydate
  from   dual
  connect by level < 36
),
w_agreements as (
      select /*+ materialize*/
             fk_contract,
             period_code,
             fk_debit,
             fk_credit,
             fk_scheme,
             fk_contragent,
             effective_date,
             pa.last_pay_date--окнечная дата зависит от period_code
      from   AGREEMENTS_LIST_T pa 
      where  1=1--pa.effective_date <= to_date(20180731, 'yyyymmdd')
    and    pa.id between 1500 and 1900
    )
select pa.fk_contract,
           pa.period_code,
           pa.fk_debit,
           pa.fk_credit,
           pa.fk_scheme,
           pa.fk_contragent,
           pa.effective_date,
           pa.last_pay_date,
           m.paydate,
           (select to_char(
                     case
                       when m.paydate = paa.from_date then
                        paa.first_amount
                       else
                        paa.amount
                     end
                   ) || '#' || to_char(paa.fk_provacct) addendums_info
            from   pension_agreement_addendums_v paa
            where  1 = 1
            and    m.paydate between paa.from_date and paa.end_date
            and    paa.fk_pension_agreement = pa.fk_contract
           ) addendums_info
    from   w_agreements pa,
           w_months     m
    where  1=1
    and    not exists(
             select 1
             from   assignments a
             where  trunc(a.paydate, 'MM') = m.paydate
             and    a.fk_paycode = 5000
             and    a.fk_asgmt_type = 2
             and    a.fk_credit = pa.fk_credit
           )
    and    not exists(
             select 1
             from   pay_restrictions pr
             where  pr.fk_document_cancel is null
             and    m.paydate between pr.effective_date and nvl(pr.expiration_date, m.paydate)
             and    pr.fk_doc_with_acct = pa.fk_contract
           )
    and    m.paydate between trunc(pa.effective_date, 'MM') and pa.last_pay_date
