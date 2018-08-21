create or replace view fnd.sp_ogr_pv_v as
  select 'SP_OGR_PV' source_table,
         op.nom_vkl, 
         op.nom_ips, 
         op.kod_ogr_pv,
         op.nach_deistv,
         op.okon_deistv,
         op.primech, 
         op.ssylka_fl, 
         op.kod_insz, 
         op.ssylka_td, 
         op.rid_td, 
         op.id
  from   sp_ogr_pv op
  where  op.kod_ogr_pv < 1000
  and    op.nom_vkl <> 1001
 union all
  select 'SP_OGR_PV_ARH' source_table,
         op.nom_vkl, 
         op.nom_ips, 
         op.kod_ogr_pv,
         op.nach_deistv,
         op.okon_deistv,
         op.primech, 
         op.ssylka_fl, 
         op.kod_insz, 
         op.ssylka_td, 
         op.rid_td, 
         op.id
  from   sp_ogr_pv_arh op
  where  op.kod_ogr_pv < 1000
  and    op.nom_vkl <> 1001
/
grant select on sp_ogr_pv_v to gazfond
/
