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
*/
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
/
select *
