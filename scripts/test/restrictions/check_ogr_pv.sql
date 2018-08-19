select --count(1) /*
       op.kod_ogr_pv,op.ssylka_fl, op.nach_deistv
       --*/
from   sp_ogr_pv_v op
minus
select count(1)/*
       op.kod_ogr_pv,op.ssylka_fl, op.nach_deistv
       --*/
from   sp_ogr_pv_imp_v op
/
select count(1)/*
       opi.kod_ogr_pv,opi.ssylka_fl, opi.nach_deistv, min(opi.pd_data_nach_vypl) min_nach_vypl, max(opi.pd_data_nach_vypl) max_nach_vypl
       --*/
from   sp_ogr_pv_imp_v opi
group by opi.kod_ogr_pv, opi.ssylka_fl, opi.nach_deistv
having count(1) > 1
/

--из GAZFOND
select count(1)
from   fnd.sp_ogr_pv_imp_v    op,
       transform_contragents  tc,
       pension_agreements     pa
where  1=1
and    pa.fk_base_contract is null
and    pa.effective_date(+) = op.pd_data_nach_vypl
and    pa.fk_base_contract(+) = tc.fk_contract
and    tc.ssylka_fl = op.ssylka_fl
/
--пересекающиеся по периодам ограничения
select *
from   (
        select op.ssylka_fl,
               op.nach_deistv,
               coalesce(op.okon_deistv, to_date(21000101, 'yyyymmdd')) okon_deistv,
               lag(op.nach_deistv)over(partition by op.ssylka_fl order by op.nach_deistv, op.kod_ogr_pv) prev_nach_deistv,
               coalesce(lag(op.okon_deistv)over(partition by op.ssylka_fl order by op.nach_deistv, op.kod_ogr_pv), to_date(21000101, 'yyyymmdd')) prev_okon_deistv
        from   fnd.sp_ogr_pv_imp_v    op
       ) op
where  not(op.prev_okon_deistv < op.nach_deistv or op.prev_nach_deistv > op.okon_deistv)
