/*
select distinct vp.tip_vypl, kpv.nazv_vypl, kpv.komment_otch --vp.*
from   vyplach_posob vp,
       KOD_PEN_VYPL  kpv
where  1=1--vp.ssylka = 3759
and    kpv.kod_pen_vypl = vp.tip_vypl
--KOD_PEN_VYPL
*/
select kpv.nazv_vypl, vp.*
from   vyplach_posob vp,
       KOD_PEN_VYPL  kpv
where  1=1--
and    vp.ssylka = 7350288
and    kpv.kod_pen_vypl = vp.tip_vypl
/
select *
from   sp_ritual_pos rp
where  rp.ssylka = 7350288
--KOD_PEN_VYPL
