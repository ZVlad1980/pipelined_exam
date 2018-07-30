create or replace view sp_pen_dog_vypl_v as
  select pd.dog_rn,
         pd.dog_cnt,
         pd.ssylka,
         pd.source_table,
         pd.nom_vkl,
         pd.nom_ips,
         pd.fio,
         pd.status_pen,
         pd.data_nach_vypl,
         pd.nach_vypl_pen              pd_nach_vypl_pen, --дата начала начислений!
         trunc(pd.nach_vypl_pen, 'MM') nach_vypl_pen,
         trunc(least(coalesce(pd.okon_vypl_pen, sysdate), coalesce(pd.nach_vypl_pen_next + 1, sysdate)), 'MM') - 1 data_okon_vypl,
         pd.type_dog,
         pd.shema_dog,
         pd.razm_pen,
         pd.data_perevoda_5_cx,
         pd.ref_kodinsz,
         last_day(pd.nach_vypl_pen) -  pd.nach_vypl_pen + 1     first_pay_days,
         round(pd.razm_pen / extract(day from last_day(pd.nach_vypl_pen)) * (last_day(pd.nach_vypl_pen) -  pd.nach_vypl_pen + 1), 2) first_pay_amount
  from   sp_pen_dog_v pd
/
grant select on sp_pen_dog_vypl_v to gazfond
/
