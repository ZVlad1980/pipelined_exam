create or replace view sp_ogr_pv_rev_v as
  select op.source_table,
         op.nom_vkl,
         op.nom_ips,
         op.kod_ogr_pv,
         case op.kod_ogr_pv
           when 3 then
             op.okon_deistv + 1
           else op.nach_deistv
         end nach_deistv,
         case op.kod_ogr_pv
           when 3 then
             lead(op.nach_deistv)over(partition by op.ssylka_fl, op.kod_ogr_pv order by op.nach_deistv, op.id) - 1
           else op.okon_deistv
         end okon_deistv,
         op.primech,
         op.ssylka_fl,
         op.kod_insz,
         op.ssylka_td,
         op.rid_td,
         op.id,
         op.nach_deistv real_nach_deistv,
         op.okon_deistv real_okon_deistv
  from   sp_ogr_pv_v      op
/
grant select on sp_ogr_pv_rev_v to gazfond
/
