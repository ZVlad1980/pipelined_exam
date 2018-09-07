with w_po_params as (
  select /*+ materialize*/
         &p_pay_date                        paydate,
         last_day(&p_pay_date)              lst_day_month,
         trunc(add_months(&p_pay_date, 3), 'Q') - 1 lst_day_quarter,
         ADD_MONTHS(TRUNC(&p_pay_date, 'Y'), TRUNC((TO_CHAR(&p_pay_date, 'MM') - 1) / 6) * 6 + 6) - 1 lst_day_halfyear,
         to_date(extract(year from &p_pay_date) || '1231', 'yyyymmdd') lst_day_year
  from   dual
)
select /*+ parallel(4)*/
       rownum,
       fk_contract,
       period_code,
       fk_debit,
       fk_credit,
       fk_scheme,
       fk_contragent,
       effective_date,
       least(last_pay_date, 
         case
           when period_code = 1 then lst_day_month
           when period_code = 3 then lst_day_quarter
           when period_code = 6 then lst_day_halfyear
           when period_code = 12 then lst_day_year
         end
       ) last_pay_date, --окнечная дата зависит от period_code
       pa.creation_date,
       pa.first_pay
from   w_po_params                 pp,
       pension_agreements_charge_v pa
where  pa.effective_date <= pp.paydate
and    pa.period_code = 3
;
