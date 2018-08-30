select t.pd_data_nach_vypl, t.ssylka_fl, t.nach_deistv, count(1) cnt, min(t.kod_ogr_pv) min_kod_ogr_pv, max(t.kod_ogr_pv) max_kod_ogr_pv
from   fnd.sp_ogr_pv_imp_v t
where  1=1--t.source_table = 'SP_OGR_PV'
and    t.is_cancelled = 'N'
group by t.pd_data_nach_vypl, t.ssylka_fl, t.nach_deistv
having count(1) > 1
order by t.ssylka_fl, t.nach_deistv
/
