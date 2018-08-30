select *
from   sp_ogr_pv_v op
where  1=1
and    not exists (
         select 1
         from   sp_lspv lspv
         where  lspv.ssylka_fl = op.ssylka_fl
         and    lspv.status_pen = 'и'
         union all
         select 1
         from   sp_invalid_v inv
         where  inv.ssylka_fl = op.ssylka_fl
       )
and    op.kod_ogr_pv = 3
and    op.okon_deistv is not null
and    op.source_table = 'SP_OGR_PV'
/
select *
from   sp_ogr_pv_v op
where  op.ssylka_fl = 1644853
/
select *
from   sp_pen_dog_v pd
where  pd.ssylka = 1644853
/
select *
from   vypl_pen vp
where  vp.ssylka_fl = 1644853
