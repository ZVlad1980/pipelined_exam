create or replace view pension_agreement_addendums_v as 
  select   paa.fk_pension_agreement,
           paa.from_month from_date,
           max(greatest(case when paa.end_date <> last_day(paa.end_date) then trunc(paa.end_date, 'MM') - 1 else paa.end_date end, paa.last_day_from_month)) end_date,
           round(sum(
             case
               when paa.month_serialno = 1 and paa.from_month <> paa.alt_date_begin and paa.amount_prev is not null then
                 paa.amount_prev / extract(day from paa.last_day_from_month) * (paa.alt_date_begin - paa.from_month)
               else 0
             end +
             paa.amount / extract(day from last_day(paa.from_month)) * (least(paa.end_date, paa.last_day_from_month) - paa.alt_date_begin + 1)
           ), 2) first_amount,
           max(amount) amount,
           max(paa.fk_provacct) keep(dense_rank last order by paa.month_serialno) fk_provacct
  from     pa_addendums_det_v paa
  group by paa.fk_pension_agreement, paa.from_month
/
