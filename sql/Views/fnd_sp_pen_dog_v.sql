create or replace view fnd.sp_pen_dog_v as
  with w_pen_dog_excl as (
    select /*+ materialize*/t.ssylka_fl, t.data_arh
    from   (select 1508    ssylka_fl,    to_date(20040509173344, 'yyyymmddhh24miss') data_arh from dual union all
            select 1610,    to_date(20040509173344, 'yyyymmddhh24miss') from dual union all
            select 4097,    to_date(20060718171506, 'yyyymmddhh24miss') from dual union all
            select 21957,    to_date(20040509173344, 'yyyymmddhh24miss') from dual union all
            select 28757,    to_date(20040509173344, 'yyyymmddhh24miss') from dual union all
            select 30107,    to_date(20040509173344, 'yyyymmddhh24miss') from dual union all
            select 33849,    to_date(20040509173344, 'yyyymmddhh24miss') from dual union all
            select 35870,    to_date(20040509173344, 'yyyymmddhh24miss') from dual union all
            select 90172,    to_date(20160426135328, 'yyyymmddhh24miss') from dual union all
            select 98605,    to_date(20140120110331, 'yyyymmddhh24miss') from dual union all
            select 98658,    to_date(20101227142133, 'yyyymmddhh24miss') from dual union all
            select 102043,    to_date(20110128105853, 'yyyymmddhh24miss') from dual union all
            select 142653,    to_date(20160414131349, 'yyyymmddhh24miss') from dual union all
            select 152134,    to_date(20160226104851, 'yyyymmddhh24miss') from dual union all
            select 187692,    to_date(20160426135450, 'yyyymmddhh24miss') from dual union all
            select 238814,    to_date(20160623170234, 'yyyymmddhh24miss') from dual union all
            select 311206,    to_date(20110503160028, 'yyyymmddhh24miss') from dual union all
            select 1033359,    to_date(20160513122957, 'yyyymmddhh24miss') from dual union all
            select 1658415,    to_date(20160517140818, 'yyyymmddhh24miss') from dual
           ) t
  ),
  w_pen_dog as (
    select 'SP_PEN_DOG' source_table,
           pd.nom_vkl, 
           pd.nom_ips, 
           pd.fio, 
           cast(null as date) data_arh,
           pd.data_otkr, 
           pd.ssylka, 
           lspv.status_pen,
           coalesce(lspv.nach_vypl_pen, pd.data_nach_vypl) nach_vypl_pen,
           coalesce(lspv.data_zakr, pd.data_okon_vypl)     okon_vypl_pen,
           pd.data_nach_vypl,
           pd.data_okon_vypl, 
           pd.razm_pen, 
           pd.delta_pen, 
           pd.delta_pere, 
           pd.summa, 
           pd.summa_u, 
           pd.summa_c, 
           pd.data_dog, 
           pd.nom_dog, 
           pd.flag, 
           pd.kod_oper, 
           pd.flg_admin, 
           pd.data, 
           pd.sopr_oper, 
           pd.nom_pz, 
           pd.type_dog, 
           pd.data_uvoln, 
           pd.shema_dog, 
           pd.data_perevoda_5_cx,
           pd.id_period_payment, 
           pd.id_letter, 
           pd.ref_kodinsz, 
           pd.kod_insz, 
           pd.summa_perevoda_5_cx,
           pd.data                 cntr_print_date,
           trunc(coalesce(pd.data, pd.data_nach_vypl))  cntr_date
    from   sp_pen_dog pd,
           sp_lspv    lspv
    where  lspv.ssylka_fl(+) = pd.ssylka
    union all
    select 'SP_PEN_DOG_ARH' source_table,
           pda.nom_vkl, 
           pda.nom_ips, 
           pda.fio, 
           pda.data_arh,
           pda.data_otkr, 
           pda.ssylka, 
           'A' status_pen,
           pda.data_nach_vypl nach_vypl_pen,
           pda.data_okon_vypl okon_vypl_pen,
           pda.data_nach_vypl, 
           pda.data_okon_vypl, 
           pda.razm_pen, 
           pda.delta_pen, 
           pda.delta_pere, 
           pda.summa, 
           pda.summa_u, 
           pda.summa_c, 
           pda.data_dog, 
           pda.nom_dog, 
           pda.flag, 
           pda.kod_oper, 
           pda.flg_admin, 
           pda.data, 
           pda.sopr_oper, 
           pda.nom_pz, 
           pda.type_dog, 
           pda.data_uvoln, 
           pda.shema_dog, 
           pda.data_perevoda_5_cx,
           pda.id_period_payment, 
           pda.id_letter, 
           pda.ref_kodinsz, 
           pda.kod_insz, 
           pda.summa_perevoda_5_cx,
           pda.data_arh                 cntr_print_date,
           trunc(coalesce(pda.data_arh, pda.data_nach_vypl))  cntr_date
    from   sp_pen_dog_arh pda
    where  (pda.ssylka, pda.data_arh) not in ( --исключиения!
             select pde.ssylka_fl, pde.data_arh
             from   w_pen_dog_excl pde
           )
  )
  select row_number()over(partition by pd.ssylka order by pd.data_nach_vypl) dog_rn,
         count(1)over(partition by pd.ssylka) dog_cnt,
         pd.source_table,
         pd.nom_vkl, 
         pd.nom_ips, 
         pd.fio, 
         pd.data_arh,
         pd.data_otkr, 
         pd.ssylka, 
         pd.status_pen,
         pd.data_nach_vypl,
         lead(pd.data_nach_vypl - 1) over(partition by pd.ssylka order by pd.data_nach_vypl) data_okon_vypl,
         pd.nach_vypl_pen lspv_nach_vypl_pen,
         pd.data_okon_vypl pd_data_okon_vypl,
         pd.razm_pen, 
         pd.delta_pen, 
         pd.delta_pere, 
         pd.summa, 
         pd.summa_u, 
         pd.summa_c, 
         pd.data_dog, 
         pd.nom_dog, 
         pd.flag, 
         pd.kod_oper, 
         pd.flg_admin, 
         pd.data, 
         pd.sopr_oper, 
         pd.nom_pz, 
         pd.type_dog, 
         pd.data_uvoln, 
         pd.shema_dog, 
         pd.data_perevoda_5_cx,
         pd.id_period_payment, 
         pd.id_letter, 
         pd.ref_kodinsz, 
         pd.kod_insz, 
         pd.summa_perevoda_5_cx,
         pd.cntr_print_date,
         pd.cntr_date
  from   w_pen_dog pd
  where  pd.nom_vkl <> 1001
/
grant select on sp_pen_dog_v to gazfond
/
