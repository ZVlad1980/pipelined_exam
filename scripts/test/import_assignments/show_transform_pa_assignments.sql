select t.state, min(t.date_op) min_date_op, max(t.date_op) max_date_op, min(t.creation_date) creation_date, max(t.last_update_date) last_update_date, count(1) cnt
from   transform_pa_assignments t
group by t.state
order by t.state
/
select t.pay_month, t.creation_date, t.last_update_date,
       lag(t.last_update_date)over(order by t.pay_month) prev_update_date,
       round((t.last_update_date - lag(t.last_update_date)over(order by t.pay_month)) * 24*60, 2) duration_min
from   (
select trunc(t.date_op, 'MM') pay_month, min(t.creation_date) creation_date, max(t.last_update_date) last_update_date
from   transform_pa_assignments t
group by trunc(t.date_op, 'MM')
) t
where t.last_update_date is not null
order by t.pay_month
/
select t.*, t.rowid
from   transform_pa_assignments t
--where  t.date_op > to_date(20161101, 'yyyymmdd')--t.state = 'E'
order by t.date_op
/
