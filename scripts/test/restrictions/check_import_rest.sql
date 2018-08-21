select t.kod_ogr_pv, case when t.okon_deistv is null then 'Y' else 'N' end unlimit, count(1)
from   transform_pa_restrictions t
--where  t.okon_deistv is not null
group by t.kod_ogr_pv, case when t.okon_deistv is null then 'Y' else 'N' end
/
select *
from   pay_restrictions pr
/
select op.kod_ogr_pv, op.ssylka_fl, op.nach_deistv
from   fnd.sp_ogr_pv_v op
where  op.kod_ogr_pv = 6
and    op.okon_deistv is null
minus
select t.kod_ogr_pv, t.ssylka, t.nach_deistv
from   transform_pa_restrictions t
where  t.kod_ogr_pv = 6
and    t.okon_deistv is null
