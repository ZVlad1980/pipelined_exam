with w_pay_order as ( --обрабатываемый pay_order
  select /*+ materialize*/
         po.fk_document,
         po.start_month, 
         po.end_month, 
         po.start_quarter, 
         po.end_quarter, 
         po.start_halfyear,
         po.end_half_year, 
         po.start_year, 
         po.end_year
  from   pay_orders_charge_v po
  where  po.fk_document = 23601738 --:fk_pay_order !!!
),
w_months as ( --список обрабатываемых месяцев
  select /*+ materialize*/
         m.month_date,
         last_day(m.month_date) end_month_date
  from   w_pay_order po,
         lateral(
              select add_months(trunc(po.end_year, 'MM'), -1 * (level - 1)) month_date
              from   dual
              connect by level < 121 --:depth_months
         ) m
)
select pa.fk_contract,
       coalesce(
         --to_number(substr(pa.paa_info, 1, instr(pa.paa_info, '#') - 1)),
         pa.fk_provacct,
         pa.fk_debit
       ) fk_debit,
       pa.fk_credit,
       pa.fk_company,
       pa.fk_scheme,
       pa.fk_contragent,
       pa.effective_date,
       pa.expiration_date,
       pa.month_date paydate,
       trunc(least(pa.last_pay_date, pa.end_month_date)) - trunc(greatest(pa.month_date, pa.effective_date)) + 1 paydays,
       --to_number(substr(pa.paa_info, instr(pa.paa_info, '#') + 1)) pay_amount,
       pa.amount pay_amount,
       pa.last_pay_date,
       pa.period_code,
       pa.end_month_date
from   (
        select pa.fk_contract,
               pa.fk_debit,
               pa.fk_credit,
               pa.fk_company,
               pa.fk_scheme,
               pa.fk_contragent,
               pa.effective_date,
               pa.expiration_date,
               m.month_date,
               m.end_month_date,
               /*(select to_char(paa.fk_provacct) || '#' ||
                         to_char(case when m.month_date = paa.from_date then paa.first_amount else paa.amount end) paa_info
                from   pension_agreement_addendums_v paa
                where  m.month_date between paa.from_date and paa.end_date
                and    paa.fk_pension_agreement = pa.fk_contract
               ) paa_info,*/
               case when m.month_date = paa.from_date then paa.first_amount else paa.amount end amount,
               paa.fk_provacct,
               last_day(least(pa.last_pay_date, case pa.period_code 
                     when 1 then po.end_month
                     when 3 then po.end_quarter
                     when 6 then po.end_half_year
                     when 12 then po.end_year
                   end)) last_pay_date,
               period_code
        from   w_pay_order                   po,
               pension_agreements_charge_v   pa,
               w_months                      m,
               pension_agreement_addendums_v paa
        where  1 = 1
        and    m.month_date between paa.from_date and paa.end_date
        and    paa.fk_pension_agreement = pa.fk_contract
        and    not exists (
                 select 1
                 from   assignments a
                 where  1=1
                 and    a.fk_paycode = 5000
                 and    a.fk_doc_with_acct = pa.fk_contract
                 and    a.paydate between m.month_date and m.end_month_date 
                 and    a.fk_asgmt_type = 2
               )
        and    not exists (
                  select 1
                  from   pay_restrictions pr
                  where  pr.fk_document_cancel is null
                  and    m.month_date between pr.effective_date and nvl(pr.expiration_date, m.month_date)
                  and    pr.fk_doc_with_acct = pa.fk_contract
               ) --*/
        and    m.month_date between trunc(pa.effective_date, 'MM') and 
                 least(pa.last_pay_date, 
                   case pa.period_code 
                     when 1 then po.end_month
                     when 3 then po.end_quarter
                     when 6 then po.end_half_year
                     when 12 then po.end_year
                   end
                 )
        and    pa.effective_date <= po.end_month
        and    pa.fk_contract = 23419832
       ) pa
