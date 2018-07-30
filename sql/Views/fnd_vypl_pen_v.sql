create or replace view vypl_pen_v as
  select pd.status_pen,
         pd.ssylka,
         pd.data_nach_vypl,
         pd.nach_vypl_pen,
         pd.data_okon_vypl,
         pd.ref_kodinsz,
         pd.shema_dog,
         pd.data_perevoda_5_cx,
         vp.data_op,
         vp.data_nachisl,
         vp.tip_vypl,
         vp.summa,
         vp.oplach_dni,
         vp.nom_vkl,
         vp.nom_ips
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
/
grant select on vypl_pen_v to gazfond, gazfond_pn
/
