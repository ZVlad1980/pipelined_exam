select trunc(vp.data_op, 'Y') year_op,
       count(1)               cnt_year_op
from   vypl_pen          vp,
       sp_pen_dog_vypl_v pd
where  1=1
and    pd.shema_dog in (1, 2, 3, 4, 5, 6, 8)
and    last_day(vp.data_nachisl) between pd.nach_vypl_pen and pd.data_okon_vypl
and    pd.ssylka = vp.ssylka_fl
group by trunc(vp.data_op, 'Y')
order by trunc(vp.data_op, 'Y')
