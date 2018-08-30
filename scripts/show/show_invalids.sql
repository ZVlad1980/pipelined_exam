with w_invalid as (
  select /*+ materialize*/
         'SP_INVALID' tbl,
         inv.ssylka_fl,
         inv.grup_inv,
         inv.data_zakl_vtek,
         inv.nom_zakl_vtek,
         inv.summa_ips,
         inv.summa_rsf,
         inv.summa_ips_u,
         inv.summa_ips_f,
         inv.pereosv,
         inv.data_pens
  from   sp_invalid     inv
  union all
  select 'SP_INVALID_ARH' tbl,
         inv.ssylka_fl,
         inv.grup_inv,
         inv.dat_zakl_vtek ,
         inv.nom_zakl_vtek,
         inv.summa_ips,
         inv.summa_rsf,
         inv.summa_ips_u,
         inv.summa_ips_f,
         to_date(inv.pereosv, 'dd.mm.yyyy') pereosv,
         to_date(inv.data_pens, 'dd.mm.yyyy') data_pens
  from   sp_invalid_arh     inv
)
select inv.*,
       sfl.familiya || ' ' || sfl.imya ||  ' ' || sfl.otchestvo || ' (' || to_char(sfl.data_rogd, 'dd.mm.yyyy') || ')'full_name,
       ls.nom_vkl,
       ls.nom_ips,
       count(1)over(partition by inv.ssylka_fl) row_cnt,
       pd.cnt pen_dog_cnt,
       pda.cnt pen_dog_arh_cnt,
       least(coalesce(pd.min_data_nach_vypl, sysdate), coalesce(pda.min_data_nach_vypl, sysdate)) min_data_nach_vypl,
       greatest(coalesce(pd.max_data_nach_vypl, sysdate - 365 * 50), coalesce(pda.max_data_nach_vypl, sysdate - 365 * 50)) max_data_nach_vypl,
       vp.min_data_nachisl,
       vp.max_data_nachisl
from   w_invalid    inv,
       sp_lspv      ls,
       sp_fiz_lits  sfl,
       lateral(
         select count(1) cnt,
                min(pd.data_nach_vypl) min_data_nach_vypl,
                max(pd.data_nach_vypl) max_data_nach_vypl
         from   sp_pen_dog pd
         where  pd.ssylka = inv.ssylka_fl
       )(+) pd,
       lateral(
         select count(1) cnt,
                min(pda.data_nach_vypl) min_data_nach_vypl,
                max(pda.data_nach_vypl) max_data_nach_vypl
         from   sp_pen_dog_arh pda
         where  pda.ssylka = inv.ssylka_fl
       )(+) pda,
       lateral(
         select min(vp.data_nachisl) min_data_nachisl,
                max(vp.data_nachisl) max_data_nachisl
         from   vypl_pen vp
         where  vp.nom_vkl = ls.nom_vkl
         and    vp.nom_ips = ls.nom_ips
       )(+) vp
where  1=1
and    sfl.ssylka = inv.ssylka_fl
and    ls.ssylka_fl(+) = inv.ssylka_fl
and    inv.ssylka_fl > 0
order by inv.ssylka_fl, inv.tbl
/
/*

/
select count(1)
from   sp_lspv ls,
       sp_invalid inv,
       sp_pen_dog     pd,
       sp_pen_dog_arh pda
where  1=1
and    pd.ssylka(+) = inv.ssylka_fl
and    pda.ssylka(+) = inv.ssylka_fl
and    inv.ssylka_fl = ls.ssylka_fl
and    ls.status_pen = 'и'
*/
