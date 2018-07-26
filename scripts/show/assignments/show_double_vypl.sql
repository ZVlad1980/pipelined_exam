with w_double_vypl as (
  select /*+ materialize*/
         vp.ssylka_fl,
         min(vp.data_nachisl) min_data_nachisl,
         max(vp.data_nachisl) max_data_nachisl,
         min(pd.nach_vypl_pen) min_nach_vypl_pen,
         max(pd.nach_vypl_pen) max_nach_vypl_pen
  --select vp.*
  from   sp_pen_dog_vypl_v pd,
         vypl_pen          vp
  where  1=1
  --and    trunc(vp.data_nachisl, 'MM') = pd.nach_vypl_pen
  /*and    (
           pd.dog_cnt = 1
          or 
           (pd.dog_rn = 1 and trunc(vp.data_nachisl, 'MM') < pd.nach_vypl_pen) 
          or
           (trunc(vp.data_nachisl, 'MM') between trunc(pd.nach_vypl_pen, 'MM') and last_day(pd.data_okon_vypl))
         )*/
  and    ((pd.dog_rn > 1 and trunc(vp.data_nachisl, 'MM') = trunc(pd.nach_vypl_pen, 'MM'))
         or
          (pd.dog_rn < pd.dog_cnt and trunc(vp.data_nachisl, 'MM') = trunc(pd.data_okon_vypl, 'MM'))
         )
  --and    vp.data_op < to_date(19970101, 'yyyymmdd')
  and    vp.ssylka_fl = pd.ssylka
  --and    pd.ssylka = 2879
  --and    pd.ssylka = 380
  and    pd.dog_cnt > 1
  
  group by vp.ssylka_fl, trunc(vp.data_nachisl, 'MM')
  having count(distinct pd.nach_vypl_pen) > 1
)
select count(1)over(partition by vp.ssylka_fl) cnt,
       pd.status_pen,
       dvp.min_data_nachisl,
       dvp.max_data_nachisl,
       vp.ssylka_fl,
       vp.data_nachisl,
       vp.tip_vypl,
       vp.oplach_dni,
       vp.summa,
       pd.first_pay_days,
       pd.first_pay_amount,
       dvp.min_nach_vypl_pen,
       pd.nach_vypl_pen,
       pd.razm_pen,
       pd.ref_kodinsz,
       pd2.ref_kodinsz prev_ref_kodinsz
from   w_double_vypl      dvp,
       vypl_pen           vp,
       sp_pen_dog_vypl_v  pd,
       sp_pen_dog_vypl_v  pd2
where  1 = 1
and    pd2.nach_vypl_pen = min_nach_vypl_pen
and    pd2.ssylka = vp.ssylka_fl
and    pd.nach_vypl_pen = max_nach_vypl_pen
and    pd.ssylka = vp.ssylka_fl
and    vp.data_nachisl between dvp.min_data_nachisl and dvp.max_data_nachisl
and    vp.ssylka_fl = dvp.ssylka_fl
order  by dvp.ssylka_fl
