create or replace view sp_ogr_pv_imp_v as
  select op.source_table,
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
         op.id,
         op.real_nach_deistv,
         op.real_okon_deistv,
         pd.data_nach_vypl,
         case when op.source_table = 'SP_OGR_PV_ARH' or op.okon_deistv <= op.nach_deistv then 'Y' else 'N' end is_cancel,
         count(1)over(partition by op.ssylka_fl, pd.data_nach_vypl, op.nach_deistv) cnt,
         row_number()over(partition by op.ssylka_fl, pd.data_nach_vypl, op.nach_deistv order by op.kod_ogr_pv, op.real_nach_deistv) rn
  from   sp_ogr_pv_rev_v  op,
         sp_pen_dog_imp_v pd
  where  1=1
  and    op.nach_deistv between pd.from_date and pd.to_date
  and    pd.ssylka = op.ssylka_fl
  and    op.nach_deistv < to_date(20500101, 'yyyymmdd')
/
grant select on sp_ogr_pv_imp_v to gazfond
/
