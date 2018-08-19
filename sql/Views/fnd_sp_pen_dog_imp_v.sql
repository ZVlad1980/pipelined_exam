create or replace view sp_pen_dog_imp_v as
  select pd.dog_rn,
         pd.dog_cnt,
         pd.ssylka,
         pd.source_table,
         pd.nom_vkl,
         pd.nom_ips,
         pd.fio,
         pd.status_pen,
         case
           when pd.dog_rn = 1 then
             to_date(19950101, 'yyyymmdd')
           else 
             trunc(pd.data_nach_vypl, 'MM')
         end                           from_date,
         case
           when pd.dog_rn = pd.dog_cnt then
             trunc(sysdate)
           else 
             trunc(pd.data_okon_vypl, 'MM') - 1
         end                           to_date,
         pd.data_nach_vypl,
         pd.data_okon_vypl,
         pd.lspv_nach_vypl_pen,
         pd.pd_data_okon_vypl,
         pd.data_otkr,
         pd.type_dog,
         pd.shema_dog,
         pd.razm_pen,
         pd.data_perevoda_5_cx,
         pd.ref_kodinsz,
         pd.data_arh,
         pd.data
  from   sp_pen_dog_v pd
/
grant select on sp_pen_dog_imp_v to gazfond
/
