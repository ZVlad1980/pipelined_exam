select *
from   transform_pa_assignments t
where  t.state = 'N'
order  by date_op
