select count(1)over(partition by t.ssylka) cnt, t.ssylka, t.fio_poluch_dat, t.min_dat_zanes, t.max_dat_zanes, 
       rp.data_smerti, rp.status_pen,
       fl.*
from   (
select t.ssylka, t.fio_poluch_dat, min(t.dat_zanes) min_dat_zanes, max(t.dat_zanes) max_dat_zanes
from   VYPL_NASLED t
group by t.ssylka, t.fio_poluch_dat
) t,
sp_fiz_lits fl,
sp_ritual_pos rp
where   fl.ssylka = t.ssylka
and     rp.ssylka = t.ssylka
order by t.ssylka, t.fio_poluch_dat
/
select *
from   vypl_pen vp
where  vp.ssylka_fl = 1658596
