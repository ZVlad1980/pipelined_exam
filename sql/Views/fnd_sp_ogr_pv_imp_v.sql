create or replace view sp_ogr_pv_imp_v as
  select op.source_table,
         op.nom_vkl,
         op.nom_ips,
         op.kod_ogr_pv,
         op.nach_deistv,
         case
           when op.okon_deistv >= op.nach_deistv then op.okon_deistv end okon_deistv,
         op.primech,
         op.ssylka_fl,
         op.kod_insz,
         op.ssylka_td,
         op.rid_td,
         op.id,
         op.real_nach_deistv,
         op.real_okon_deistv,
         pd.data_nach_vypl,
         case
           when op.source_table = 'SP_OGR_PV_ARH' or op.okon_deistv <= op.nach_deistv
             then 'Y'
           when op.kod_ogr_pv = 3 and pd.dog_rn = pd.dog_cnt and exists(
                  select 1
                  from   vypl_pen vp
                  where  vp.ssylka_fl = op.ssylka_fl
                  and    vp.data_nachisl between op.nach_deistv and coalesce(op.okon_deistv, vp.data_nachisl)
                )
             then 'Y'
           else 'N'
         end is_cancel,
         count(1)over(partition by op.ssylka_fl, pd.data_nach_vypl, op.nach_deistv) cnt,
         row_number()over(partition by op.ssylka_fl, pd.data_nach_vypl, op.nach_deistv order by op.kod_ogr_pv, op.real_nach_deistv, case op.source_table when 'SP_OGR_PV' then 2 else 1 end) rn
  from   sp_ogr_pv_rev_v  op,
         sp_pen_dog_imp_v pd
  where  1=1
  and    op.real_nach_deistv between 
           case when pd.dog_rn = 1 then pd.from_date else pd.data_nach_vypl end 
             and
           case when pd.dog_rn = pd.dog_cnt then pd.TO_DATE else coalesce(pd.data_okon_vypl, op.real_nach_deistv) end
  and    pd.ssylka = op.ssylka_fl
  and    op.nach_deistv < to_date(20500101, 'yyyymmdd')
  and    (
          (op.kod_ogr_pv <> 3)
          or
          (op.kod_ogr_pv = 3 and  op.real_okon_deistv is not null)
         )
/
grant select on sp_ogr_pv_imp_v to gazfond
/
