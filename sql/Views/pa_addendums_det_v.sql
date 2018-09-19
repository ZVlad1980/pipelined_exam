create or replace view pa_addendums_det_v as 
  select paa.id,
         trunc(paa.alt_date_begin, 'MM') from_month,
         paa.alt_date_begin from_date,
         nvl(lead(paa.alt_date_begin - 1)over(partition by paa.fk_pension_agreement order by serialno), to_date(47121231, 'yyyymmdd') + 1) end_date,
         paa.fk_pension_agreement,
         paa.fk_provacct, 
         paa.serialno, 
         row_number()over(partition by paa.fk_pension_agreement, trunc(paa.alt_date_begin, 'MM') order by serialno) month_serialno,
         lag(paa.amount)over(partition by paa.fk_pension_agreement order by serialno) amount_prev,
         paa.amount,
         paa.alt_date_begin, 
         paa.alt_date_end,
         last_day(paa.alt_date_begin) last_day_from_month
  from   pension_agreement_addendums paa
  where  paa.canceled = 0
/
