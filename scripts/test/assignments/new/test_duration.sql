--/*
declare
  cnt int := 0;
  l_start_time number;
  l_chunk_time number;
  l_chunk_size number := 1000;
  
  cursor l_assignments_cur is 
  --*/
    with w_agreements as (
      select /*+ materialize*/
             fk_contract,
             period_code,
             fk_debit,
             fk_credit,
             fk_scheme,
             fk_contragent,
             effective_date,
             least(last_pay_date, to_date(20180731, 'yyyymmdd')) last_pay_date--окнечная дата зависит от period_code
      from   pension_agreements_charge_v pa 
      where  pa.effective_date <= to_date(20180731, 'yyyymmdd')
    ),
    w_months(paydate) as (
      select /*+ materialize*/ add_months(to_date(19950101, 'yyyymmdd'), level - 1) paydate
      from   dual
      connect by level < 284
    )
    select /*+ parallel(4)*/
           pa.fk_contract,
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
  --/*
  ;
  type l_assignments_typ is table of l_assignments_cur%rowtype;
  l_assignments l_assignments_typ;
begin
  --
  l_start_time := dbms_utility.get_time();
  l_chunk_time := l_start_time;
  open l_assignments_cur;
  cnt := 0;
  loop
    fetch l_assignments_cur
      bulk collect into l_assignments limit l_chunk_size;
    exit when l_assignments.count = 0;
    cnt := cnt + l_chunk_size;
    dbms_output.put_line(lpad(to_char((dbms_utility.get_time() - l_chunk_time)/100), 8, ' ') || ': ' || cnt);
    l_chunk_time := dbms_utility.get_time();
  end loop;
  dbms_output.put_line('Complete, duration: ' || to_char((dbms_utility.get_time() - l_start_time) / 100));
end;
--*/
