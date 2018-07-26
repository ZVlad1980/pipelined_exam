select trunc(vp.data_op, 'Y') year_op,
       count(1)               cnt_year_op
from   vypl_pen_v vp
where  1=1
group by trunc(vp.data_op, 'Y')
order by trunc(vp.data_op, 'Y')
