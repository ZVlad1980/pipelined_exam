create or replace view sp_ips_balances as
  select spd.ref_kodinsz,
         spd.ssylka,
         spd.data_nach_vypl,
         dvs.data_op date_op,
         kss.ips * dvs.summa amount,
         spd.data_perevoda_5_cx,
         dvs.shifr_schet,
         dvs.sub_shifr_schet
  from   sp_pen_dog spd,
         sp_ips     ips,
         dv_sr_ips  dvs,
         kod_shifr_schet kss
  where  1=1
  and    kss.sub_shifr_schet = dvs.sub_shifr_schet
  and    kss.shifr_schet = dvs.shifr_schet
  and    dvs.nom_ips = ips.nom_ips
  and    dvs.nom_vkl = ips.nom_vkl
  and    ips.tip_lits = case when spd.nom_vkl = 991 then 2 else 3 end
  and    ips.ssylka_fl = spd.ssylka
  and    spd.shema_dog in (2,3,4,5,8)
  and    spd.nom_vkl <> 1001 -- 992
/
grant select on sp_ips_balances to gazfond
/
