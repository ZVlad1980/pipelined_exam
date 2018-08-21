select *
from   fnd.sp_ogr_pv_v op
where  op.ssylka_fl = &ssylka
/
select *
from   fnd.sp_ogr_pv_imp_v op
where  op.ssylka_fl = &ssylka
/
select *
from   fnd.sp_pen_dog_imp_v d
where  d.ssylka = &ssylka
