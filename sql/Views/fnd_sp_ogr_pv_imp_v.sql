create or replace view sp_ogr_pv_imp_v as
  with w_sp_ogr_pv as (
    select op.source_table,
           op.nom_vkl,
           op.nom_ips,
           op.kod_ogr_pv,
           op.nach_deistv,
           case 
             when op.okon_deistv >= to_date(20991230, 'yyyymmdd') then null
             else op.okon_deistv
           end                      okon_deistv,
           case op.kod_ogr_pv
             when 3 then
               least(
                 coalesce(
                   lead(op.nach_deistv)
                     over(
                       partition by op.ssylka_fl, 
                                    op.kod_ogr_pv
                       order by op.nach_deistv, op.id
                       rows between 1 following and unbounded following
                     ) - 1,
                   to_date(99991231, 'yyyymmdd')
                 ),
                 coalesce(
                   (select pd.data_nach_vypl
                    from   sp_pen_dog pd
                    where  pd.data_nach_vypl > pd.data_nach_vypl
                    and    pd.ssylka = op.ssylka_fl
                   ) - 1,
                   to_date(99991231, 'yyyymmdd')
                 )
               )
           end                      okon_deistv_3, --окончание действия для 3 типа (наименьшая из дат: дата начала следующего ограничения типа 3 или дата соглашения с ДНВ больше текущей
           op.primech,
           op.ssylka_fl,
           op.kod_insz,
           op.ssylka_td,
           op.rid_td,
           op.id,
           pd.data_nach_vypl        pd_data_nach_vypl,
           case op.source_table
             when 'SP_OGR_PV_ARH' then 'Y'
             else 'N'
           end                      is_cancelled
    from   sp_pen_dog_imp_v pd,
           sp_ogr_pv_v      op
    where  1=1
    and    not(op.nach_deistv > pd.to_date or coalesce(op.okon_deistv, pd.from_date) < pd.from_date)
    and    op.ssylka_fl = pd.ssylka
  )
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
         op.pd_data_nach_vypl,
         op.nach_deistv real_nach_deistv,
         op.okon_deistv real_okon_deistv,
         op.is_cancelled
  from   w_sp_ogr_pv op
  where  op.kod_ogr_pv in (1, 4, 6)
 union all
  select op.source_table,
         op.nom_vkl,
         op.nom_ips,
         op.kod_ogr_pv,
         op.okon_deistv + 1 nach_deistv,
         op.okon_deistv_3   okon_deistv,
         op.primech,
         op.ssylka_fl,
         op.kod_insz,
         op.ssylka_td,
         op.rid_td,
         op.id,
         op.pd_data_nach_vypl,
         op.nach_deistv real_nach_deistv,
         op.okon_deistv real_okon_deistv,
         case
           when op.okon_deistv_3 <= op.okon_deistv then
             'Y'
           else op.is_cancelled
         end is_cancelled
  from   w_sp_ogr_pv op
  where  op.okon_deistv is not null
  and    op.kod_ogr_pv = 3
/
grant select on sp_ogr_pv_imp_v to gazfond
/
