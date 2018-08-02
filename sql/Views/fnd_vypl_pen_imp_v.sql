create or replace view vypl_pen_imp_v as
  select pd.status_pen,
         pd.ssylka ssylka_fl,
         vp.data_op,
         vp.data_nachisl,
         vp.tip_vypl,
         vp.summa,
         vp.oplach_dni,
         pd.data_nach_vypl,
         pd.data_okon_vypl,
         pd.lspv_nach_vypl_pen,
         pd.ref_kodinsz,
         pd.shema_dog,
         pd.data_perevoda_5_cx,
         vp.nom_vkl,
         vp.nom_ips,
         pd.source_table,
         pd.from_date,
         pd.to_date
  from   fnd.vypl_pen         vp,
         fnd.sp_pen_dog_imp_v pd
  where  1=1
  and    vp.data_nachisl between pd.from_date and pd.to_date
  and    pd.ssylka = vp.ssylka_fl
/
grant select on vypl_pen_imp_v to gazfond, gazfond_pn
/
