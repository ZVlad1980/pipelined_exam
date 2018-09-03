create or replace view pay_orders_charge_v as
  select po.fk_document, 
         po.payment_period, 
         po.operation_date, 
         po.payment_freqmask, 
         po.scheduled_date, 
         po.calculation_date, 
         po.fk_pay_order_type,
         po.export_err_count,
         --периоды для начисления 
         trunc(po.payment_period, 'MM')                   start_month,
         last_day(po.payment_period)                      end_month,
         trunc(po.payment_period, 'Q')                    start_quarter,
         trunc(add_months(po.payment_period, 3), 'Q') - 1 end_quarter,
         add_months(
           trunc(po.payment_period, 'Y'),
           case
             when extract(month from po.payment_period) > 6 then 6
             else 0
           end
         ) start_halfyear,
         add_months(
           trunc(po.payment_period, 'Y'),
           case
             when extract(month from po.payment_period) > 6 then 12
             else 6
           end
         ) - 1 end_half_year,
         trunc(po.payment_period, 'Y') start_year,
         to_date(extract(year from po.payment_period) || '1231', 'yyyymmdd') end_year
  from   pay_orders po
/
