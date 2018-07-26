select vp.data_op           date_op,
       min(vp.data_nachisl) min_data_nachisl,
       max(vp.data_nachisl) max_data_nachisl,
       count(1)             cnt,
       avg(vp.summa)        avg_summa
from   fnd.vypl_pen_v vp
where  vp.data_op between to_date(20170101, 'yyyymmdd') and to_date(20170331, 'yyyymmdd') --to_date(19960101, 'yyyymmdd') and to_date(19961231, 'yyyymmdd') --to_date(20180101, 'yyyymmdd') and to_date(20180331, 'yyyymmdd') --to_date(19960101, 'yyyymmdd') and to_date(19961231, 'yyyymmdd')
group by vp.data_op
order by vp.data_op
/
