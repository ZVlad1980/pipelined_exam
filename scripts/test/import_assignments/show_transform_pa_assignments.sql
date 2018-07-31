select t.*,
       case
         when exists(select 1 from err$_imp_assignments) then 'Y'
         else 'N'
       end is_error
from   (
select count(distinct (trunc(t.date_op, 'MM'))) cnt_months,
       min(date_op) min_date_op,
       max(date_op) max_date_op
from   transform_pa_assignments t
where  t.state = 'N'
order  by date_op
) t
