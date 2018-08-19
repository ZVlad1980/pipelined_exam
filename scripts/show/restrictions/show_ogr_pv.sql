select k.soderg_ogr, op.*
from   (
        select op.kod_ogr_pv,
               case when op.okon_deistv is null then 'Y' else 'N' end unlimit,
               count(1),
               min(op.nach_deistv) min_nach_deistv,
               max(op.nach_deistv) max_nach_deistv
        from   sp_ogr_pv_v op
        group by op.kod_ogr_pv, case when op.okon_deistv is null then 'Y' else 'N' end
       ) op,
       kod_ogr_pv k
where  k.kod_ogr_pv(+) = op.kod_ogr_pv
order by op.kod_ogr_pv, op.unlimit
/
select *
from   sp_ogr_pv_v op
where  1=1
and    op.ssylka_fl = &ssylka --3066 --2185438
/
select *
from   sp_pen_dog_v pd
where  pd.ssylka = &ssylka --3066 -- 2185438
/
select *
from   vypl_pen vp
where  vp.ssylka_fl = &ssylka --3066 --2185438
order by vp.data_nachisl
/
select *
from   sp_fiz_lits fl
where  fl.ssylka = &ssylka
