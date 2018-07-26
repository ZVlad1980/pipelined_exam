select vp.ssylka_fl, 
       vp.data_nachisl,
       lspv.data_otkr,
       lspv.data_otkr,
       lspv.status_pen,
       pd.shema_dog,
       pd.data_nach_vypl,
       pd.data_okon_vypl,
       pd.data_okon_vypl_next,
       pd.*
from   (
        select vp.ssylka_fl, vp.data_nachisl
        from   fnd.vypl_pen vp
        where  1=1
        and    vp.data_op between to_date(19960215, 'yyyymmdd') and to_date(19961231, 'yyyymmdd')
        minus
        select vp.ssylka_fl, vp.data_nachisl
        from   fnd.vypl_pen vp,
               fnd.sp_pen_dog_v pd
        where  1=1
        and    vp.data_nachisl between trunc(pd.data_nach_vypl, 'MM') and least(coalesce(pd.data_okon_vypl_next, vp.data_nachisl), coalesce(pd.data_okon_vypl, vp.data_nachisl), vp.data_nachisl)
        and    pd.ssylka = vp.ssylka_fl
        and    vp.data_op between to_date(19960215, 'yyyymmdd') and to_date(19961231, 'yyyymmdd')
       ) vp,
       fnd.sp_pen_dog_v pd,
       fnd.sp_lspv      lspv
where  1 = 1
and    lspv.ssylka_fl = pd.ssylka
and    pd.shema_dog in (1,2,3,4,5,6,8)
and    pd.ssylka = vp.ssylka_fl
/
