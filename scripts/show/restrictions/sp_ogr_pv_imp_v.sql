-- инвертировать тройки
--  + убрать ограничения, пересекающиеся по периодам 
select count(1)--op.*, count(1)over(partition by op.ssylka_fl, op.nach_deistv) cnt2
from   sp_ogr_pv_imp_v op
where  op.rn = op.cnt --op.is_cancel = 'N' --source_table = 'SP_OGR_PV'
and    op.ssylka_fl = 11216291
/
select *
from   sp_pen_dog_imp_v pd
where  pd.ssylka = 970497
/
select *
from   vypl_pen vp
where  vp.ssylka_fl = 970497
