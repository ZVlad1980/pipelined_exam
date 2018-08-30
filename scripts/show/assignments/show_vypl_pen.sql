select vp.ssylka_fl, 
       vp.data_nachisl,
       pd.shema_dog,
       pd.data_nach_vypl,
       pd.nach_vypl_pen,
       pd.data_okon_vypl,
       pd.dog_rn,
       pd.dog_cnt,
       lspv.data_otkr,
       lspv.data_otkr,
       lspv.status_pen
from   (
        select vp.ssylka_fl, vp.data_nachisl, vp.tip_vypl
        from   fnd.vypl_pen vp
        where  1=1
        and    vp.data_op between to_date(19960215, 'yyyymmdd') and to_date(20041231, 'yyyymmdd')
        minus
        select vp.ssylka_fl, vp.data_nachisl, vp.tip_vypl
        from   fnd.vypl_pen vp,
               fnd.sp_pen_dog_vypl_v pd
        where  1=1
        and    (
                pd.dog_cnt = 1
               or
                (pd.dog_rn = 1 and vp.data_nachisl < pd.nach_vypl_pen)
               or
                vp.data_nachisl between pd.nach_vypl_pen and pd.data_okon_vypl
               )
        and    pd.ssylka = vp.ssylka_fl
        and    vp.data_op between to_date(19960215, 'yyyymmdd') and to_date(20041231, 'yyyymmdd')
        group by vp.ssylka_fl, vp.data_nachisl, vp.tip_vypl
        having count(1) = 1
       ) vp,
       fnd.sp_pen_dog_vypl_v pd,
       fnd.sp_lspv      lspv
where  1 = 1
and    lspv.ssylka_fl = pd.ssylka
and    pd.shema_dog in (1, 2, 3, 4, 5, 6, 8)
and    pd.ssylka = vp.ssylka_fl
/
