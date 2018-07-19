select vp.tip_vypl, 
       min(vp.data_op) min_date_op,
       max(vp.data_op) max_date_op,
       count(1)        cnt,
       kpv.nazv_vypl,
       kpv.debet,
       kpv.debet_gf
from   vypl_pen     vp,
       sp_pen_dog   pd,
       kod_pen_vypl kpv
where  1=1
and    kpv.kod_pen_vypl = vp.tip_vypl
--and    vp.tip_vypl not in (1, 3, 6, 91)
and    pd.shema_dog <> 7
and    pd.ssylka = vp.ssylka_fl
and    vp.data_op between to_date(19800501, 'yyyymmdd') and to_date(20180531, 'yyyymmdd')
group by vp.tip_vypl, 
         kpv.nazv_vypl,
         kpv.debet,
         kpv.debet_gf
/
/*
select *
from   dv_sr_ips d
where  d.ssylka_doc = 823967
/
select *
from   reer_doc_ngpf doc
where  doc.ssylka = 823961
*/
--select count(1) from vypl_pen --20 789 917
