/*select spd.shema_dog,
       count(1) cnt
from   fnd.sp_pen_dog spd
where  spd.shema_dog <> 7
group by spd.shema_dog
/
select *
from   fnd.sp_pen_dog spd
where  spd.shema_dog <> 7
/
select *
from   fnd.sp_lspv
/
select spd.*,
       ls.*
from   fnd.sp_pen_dog spd,
       fnd.sp_lspv    ls
where  1=1
and    spd.nom_ips <> ls.nom_ips
and    ls.ssylka_fl = spd.ssylka
and    spd.ssylka = 883217
/
select ls.ssylka_fl, count(1)
from   fnd.sp_lspv ls
group by ls.ssylka_fl
having count(distinct ls.nom_ips) > 1
/
select *
from   fnd.sp_fiz_lits sfl
where  sfl.ssylka = 883217
*/
/*
select --lspv.status_pen, count(1)
       (select listagg(o.kod_ogr_pv || ' (' || o.nach_deistv || ' - ' || o.okon_deistv || ')') within group(order by o.nach_deistv) from sp_ogr_pv o where  o.ssylka_fl = pd.ssylka and sysdate between o.nach_deistv and nvl(o.okon_deistv, sysdate)) ogr,
       rp.data_smerti, vp.data_op, vp.data_nachisl, pd.data_nach_vypl, pd.data_okon_vypl, ks.*, lspv.*
from   sp_pen_dog     pd,
       sp_lspv        lspv,
       vypl_pen       vp,
       kod_status_pen ks,
       sp_ritual_pos  rp
where  1=1
and    rp.ssylka(+) = pd.ssylka
and    lspv.status_pen in ('п', 'и')--('с', 'о')
and    ks.id = lspv.status_pen
and    pd.data_nach_vypl <= vp.data_nachisl
and    pd.ssylka = lspv.ssylka_fl
and    lspv.nom_ips = vp.nom_ips
and    lspv.nom_vkl = vp.nom_vkl
and    vp.data_op between to_date(20180601, 'yyyymmdd') and to_date(20180630, 'yyyymmdd')
--group by lspv.status_pen
*/
--/*
select (select listagg(o.kod_ogr_pv || ' (' || to_char(o.nach_deistv, 'dd.mm.yyyy') || ' - ' || to_char(o.okon_deistv, 'dd.mm.yyyy') || ')') within group(order by o.nach_deistv) from sp_ogr_pv o where  o.ssylka_fl = lspv.ssylka_fl and sysdate between o.nach_deistv and nvl(o.okon_deistv, sysdate)) ogr,
       lspv.*
from   sp_lspv        lspv,
       kod_status_pen ks
where  1=1
and    lspv.nach_vypl_pen < to_date(20180601, 'yyyymmdd')
and    lspv.ssylka_fl not in (
         select vp.ssylka_fl
         from   vypl_pen vp
         where  vp.data_op between to_date(20180101, 'yyyymmdd') and to_date(20180630, 'yyyymmdd')
       )
and    lspv.status_pen in ('п', 'и')--('с', 'о')
and    ks.id = lspv.status_pen
--group by ks.id, ks.description

/*
select kogr.*, ogr.*
from   sp_ogr_pv  ogr,
       sp_lspv    lspv,
       kod_ogr_pv kogr
where  1=1
and    lspv.status_pen in ('п', 'и')
and    lspv.ssylka_fl = ogr.ssylka_fl
and    kogr.kod_ogr_pv = ogr.kod_ogr_pv
and    sysdate between ogr.nach_deistv and nvl(ogr.okon_deistv, sysdate)
and    ogr.kod_ogr_pv < 1000
*/
select *
from   sp_lspv lspv
where  lspv.ssylka_fl in (2,
11,
265,
4608,
4617,
18903,
37335,
38828,
297214,
1159756
)
