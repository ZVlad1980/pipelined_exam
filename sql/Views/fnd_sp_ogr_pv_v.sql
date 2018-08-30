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
  where  op.kod_ogr_pv < 100
  and    op.nom_vkl <> 1001
  and    (
          op.kod_ogr_pv <> 3 
         or
          (op.kod_ogr_pv = 3 and (
             exists(
               select 1
               from   sp_lspv lspv
               where  lspv.ssylka_fl = op.ssylka_fl
               and    lspv.status_pen = 'и'
             )
             or 
             exists(
               select 1
               from   sp_invalid_v inv
               where  inv.ssylka_fl = op.ssylka_fl
             )
            )
           )
          )
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
  where  op.kod_ogr_pv < 100
  and    op.nom_vkl <> 1001
/
grant select on sp_ogr_pv_v to gazfond
/
