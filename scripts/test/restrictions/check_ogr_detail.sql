select op.*
from   sp_ogr_pv_imp_v      op
where  op.ssylka_fl = &ssylka
/
select op.*
from   sp_pen_dog_imp_v pd,
       sp_ogr_pv_v      op
where  1=1
and    not(op.nach_deistv > pd.to_date or coalesce(op.okon_deistv, pd.from_date + 1) < pd.from_date)
and    op.ssylka_fl = pd.ssylka
and    pd.ssylka = &ssylka
/
--1	1716	6	03.06.2035		Îêîí÷àíèå äåéñòâèÿ äîãîâîðà ïî 7-é ñõåìå	1192631				444040
select *--count(1)
from   sp_ogr_pv_v op
where  op.ssylka_fl = &ssylka
/
select *
from   sp_pen_dog_imp_v pd
where  pd.ssylka = &ssylka
/
select *
from   vypl_pen vp
where  vp.ssylka_fl = &ssylka
order by vp.data_nachisl
