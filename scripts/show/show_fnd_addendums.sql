select io.ssylka, trunc(io.pen_data, 'MM'), 
       listagg(to_char(io.pen_data, 'dd.mm.yyyy'), ', ')within group(order by io.pen_data) pen_dates, 
       count(1) cnt
from   rztb_istor_obyaz io
where  io.zap_dat between trunc(sysdate - 365, 'Y') and trunc(sysdate, 'Y')
and    io.r_zapotm = 0
and    trunc(io.pen_data, 'MM') = trunc(io.zap_dat, 'MM')
group by io.ssylka, trunc(io.pen_data, 'MM')
having count(distinct to_char(trunc(io.pen_data, 'MM'), 'yyyymmdd') || '#' || to_char(io.pen_poln)) > 1
/
select io.zap_nom, io.r_zapotm, io.r_zapgen,
       io.*
from   rztb_istor_obyaz io
where  io.ssylka = 421
--and    io.r_zapotm = 0
order by io.zap_dat, io.pen_data
/
select sfl.gf_person, sfl.*
from   sp_fiz_lits sfl
where  sfl.ssylka = 421
/
select *
from   sp_pen_dog d
where  d.ssylka = 421
/
select *
from   sp_izm_pd ip
where  ip.ssylka_fl = 421
