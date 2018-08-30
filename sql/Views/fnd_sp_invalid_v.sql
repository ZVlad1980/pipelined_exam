create or replace view sp_invalid_v as
  select 'SP_INVALID' tbl,
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
  where  inv.ssylka_fl not in  (
            311413,
            218130,
            786929,
            188380,
            491724
         )
/
grant select on sp_invalid_v to gazfond
/
