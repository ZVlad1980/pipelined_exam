create or replace view pension_agreement_addendums_v as 
  select   paa.fk_pension_agreement,
           paa.from_date,
           max(greatest(case when paa.end_date <> last_day(paa.end_date) then trunc(paa.end_date, 'MM') - 1 else paa.end_date end, last_day(paa.from_date))) end_date,
           round(sum(
             case
               when paa.month_serialno = 1 and paa.from_date <> paa.alt_date_begin and paa.amount_prev is not null then
                 paa.amount_prev / extract(day from last_day(paa.from_date)) * (paa.alt_date_begin - paa.from_date)
               else 0
             end +
             paa.amount / extract(day from last_day(paa.from_date)) * (least(paa.end_date, last_day(paa.from_date)) - paa.alt_date_begin + 1)
           ), 2) first_amount,
           max(amount) amount,
           max(paa.fk_provacct) keep(dense_rank last order by paa.month_serialno) fk_provacct
  from     (
    select paa.id,
           trunc(paa.alt_date_begin, 'MM') from_date,
           nvl(lead(paa.alt_date_begin - 1)over(partition by paa.fk_pension_agreement order by serialno), to_date(47121231, 'yyyymmdd') + 1) end_date,
           paa.fk_pension_agreement,
           paa.fk_provacct, 
           paa.serialno, 
           row_number()over(partition by paa.fk_pension_agreement, trunc(paa.alt_date_begin, 'MM') order by serialno) month_serialno,
           lag(paa.amount)over(partition by paa.fk_pension_agreement order by serialno) amount_prev,
           paa.amount,
           paa.alt_date_begin, 
           paa.alt_date_end
    from   pension_agreement_addendums paa
    where  paa.canceled = 0
  ) paa
  group by paa.fk_pension_agreement, paa.from_date
/
