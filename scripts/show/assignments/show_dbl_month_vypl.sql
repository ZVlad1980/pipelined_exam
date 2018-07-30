with w_dbl as (
  select vp.ssylka, trunc(vp.data_nachisl, 'MM') data_nachisl, count(1) cnt,
         min(vp.data_op) min_data_op,
         max(vp.data_op) max_data_op
  from   fnd.vypl_pen_v vp
  where  vp.data_op <= to_date(19961231, 'yyyymmdd')
  group by vp.ssylka, trunc(vp.data_nachisl, 'MM')
  having count(1) > 1
)
select vp.ssylka_fl,
       vp.data_op,
       vp.data_nachisl,
       vp.tip_vypl,
       row_number()over(partition by d.ssylka, d.data_nachisl order by vp.data_op, vp.tip_vypl) rn
from   w_dbl d,
       fnd.vypl_pen vp
where  1=1
and    trunc(vp.data_nachisl, 'MM') = d.data_nachisl
and    vp.ssylka_fl = d.ssylka
and    vp.data_op between d.min_data_op and d.max_data_op
/
/*
with w_dbl as (
  select vp.ssylka, trunc(vp.data_nachisl, 'MM') data_nachisl, count(1) cnt
  from   vypl_pen_v vp
  where  vp.data_op between to_date(19960101, 'yyyymmdd') and to_date(19961231, 'yyyymmdd')
  group by vp.ssylka, trunc(vp.data_nachisl, 'MM')
  having count(1) > 1
)
select d.cnt,
       vp.ssylka_fl,
       vp.data_op,
       case 
         when trunc(vp.data_op, 'MM') = trunc(vp.data_nachisl, 'MM') then
           ' = '
         else '<>'
       end eq,
       vp.data_nachisl,
       vp.tip_vypl,
       vp.summa,
       pv.*
from   w_dbl d,
       vypl_pen     vp,
       kod_pen_vypl pv
where  1=1
and    d.cnt > 2
and    pv.kod_pen_vypl = vp.tip_vypl
and    vp.data_nachisl = d.data_nachisl
and    vp.ssylka_fl = d.ssylka
order by vp.ssylka_fl, vp.data_nachisl, vp.data_op, vp.tip_vypl
*/
