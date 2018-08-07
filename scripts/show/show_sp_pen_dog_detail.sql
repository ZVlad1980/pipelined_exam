select *
from   fnd.sp_pen_dog_vypl_v sp
where  sp.ssylka = &ssylka
order by sp.nach_vypl_pen
/
select *
from   pension_agreements_v  pa,
       transform_contragents tc
where  1=1
and    pa.fk_contragent = tc.fk_contragent
and    tc.ssylka_fl = &ssylka
/
select *
from   transform_pa tpa
where  1=1
and    tpa.ssylka_fl = &ssylka
/

/*
select *
from   fnd.sp_pen_dog_v sp
where  sp.ssylka = &ssylka
order by sp.nach_vypl_pen

/
select *
from   fnd.sp_izm_pd ipd
where  ipd.ssylka_fl = &ssylka
/
select *
from   fnd.rztb_istor_obyaz io
where  io.ssylka = &ssylka
and    io.r_zapotm = 0
/
select *
from   fnd.vypl_pen vp
where  vp.ssylka_fl = &ssylka
order by vp.data_nachisl
/

/*
select *
from   sp_invalid_v inv
where  inv.ssylka_fl = &ssylka
/*
select sfl.gf_person, sfl.*
from   sp_fiz_lits sfl
where  sfl.ssylka = 297214
union all
select sfl.gf_person, sfl.*
from   sp_fiz_lits sfl
where  sfl.ssylka = 182922
union all
select sfl.gf_person, sfl.*
from   sp_fiz_lits sfl
where  sfl.ssylka = 2013709
/
select vp.ssylka_fl,
       min(vp.data_nachisl) min_data_nachisl,
       max(vp.data_nachisl) max_data_nachisl
from   vypl_pen vp
where  vp.ssylka_fl in (
2,
11,
265,
4608,
4617,
5635,
18903,
20733,
29110,
37335,
38828,
42059,
44767,
48172,
52266,
54683,
67312,
109704,
133076,
237010,
297214,
1159756
)
group by vp.ssylka_fl
*/
