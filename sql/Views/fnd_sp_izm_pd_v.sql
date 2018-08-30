create or replace view fnd.sp_izm_pd_v as
  select ipd.ssylka_fl, 
         ipd.nom_izm, 
         case when ipd.id = 2060058 then to_date('20061128', 'yyyymmdd') else ipd.data_izm end data_izm, 
         ipd.summa_izm, 
         ipd.otpechatano,
         ipd.ssylka_doc,
         ipd.mod_pism, 
         ipd.data_pism, 
         ipd.sagenev, 
         ipd.dat_zanes, 
         ipd.no_otpr, 
         ipd.coment, 
         ipd.id, 
         ipd.sostoyanie,
         ipd.forma
  from   sp_izm_pd ipd
/
grant select on sp_izm_pd_v to gazfond
/
