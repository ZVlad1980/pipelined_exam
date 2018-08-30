select op.kod_ogr_pv, 
       case when grouping(op.kod_ogr_pv) = 1 then 'TOTAL' else max(kop.soderg_ogr) end soderg_ogr,
       count(1) total_cnt,
       sum(case op.source_table when 'SP_OGR_PV' then 1 end) active_cnt,
       sum(case op.source_table when 'SP_OGR_PV_ARH' then 1 end) arh_cnt,
       sum(case when op.okon_deistv is null then 1 end) unlimit_cnt
from   fnd.sp_ogr_pv_v     op,
       kod_ogr_pv          kop
where  kop.kod_ogr_pv(+) = op.kod_ogr_pv
group by rollup(op.kod_ogr_pv)--, kop.soderg_ogr
order by op.kod_ogr_pv
/
select op.kod_ogr_pv, 
       case when grouping(op.kod_ogr_pv) = 1 then 'TOTAL' else max(kop.soderg_ogr) end soderg_ogr,
       count(1) total_cnt,
       sum(case op.is_cancel when 'N' then 1 end) active_cnt,
       sum(case op.is_cancel when 'Y' then 1 end) canceled_cnt,
       sum(case when op.okon_deistv is null then 1 end) unlimit_cnt,
       min(op.nach_deistv) min_nach_deistv,
       max(op.nach_deistv) max_nach_deistv
from   fnd.sp_ogr_pv_imp_v op,
       kod_ogr_pv          kop
where  kop.kod_ogr_pv(+) = op.kod_ogr_pv
and    op.nach_deistv < to_date(20500101, 'yyyymmdd')
group by rollup(op.kod_ogr_pv)--, kop.soderg_ogr
order by op.kod_ogr_pv
/
--GAZFOND
select count(1) total_cnt,
       sum(case when pr.fk_document_cancel is null then 1 end) active_cnt,
       sum(case when pr.fk_document_cancel is not null then 1 end) cancel_cnt,
       sum(case when pr.expiration_date is null then 1 end) unlimit_cnt
from   pay_restrictions     pr
where  pr.fk_doc_with_acct in (
         select pa.fk_contract
         from   pension_agreements_v pa
       )
/*
20180824
GAZFOND:
TOTAL_CNT	ACTIVE_CNT	CANCEL_CNT	UNLIMIT_CNT
948	      948		                  948

Статистика ограничений по типам (FND)
KOD_OGR_PV  SODERG_OGR                         TOTAL_CNT   ACTIVE_CNT    ARH_CNT   UNLIMIT_CNT
1                                              568         449           119       16
2           Производится выплата наличными     1           1 
3           Продлить инвалидность с            19050       6235          12815     2691
4           Выплачено по ошибке                1           1   
6           Приостановить выплаты до 
               выяснения обстоятельств с       87224       44484         42740     86672
----------  -------------------------------    ----------  ------------  --------  ------------
  TOTAL                                        106844      51169         55675     89379


IMPORT:
KOD_OGR_PV  SODERG_OGR                         TOTAL_CNT ACTIVE_CNT  CANCELED_CNT  UNLIMIT_CNT MIN_NACH_DEISTV MAX_NACH_DEISTV
1                                              568       448         120           17          15.01.1996      01.10.2007
2           Производится выплата наличными     1         1                                     01.01.1996      01.01.1996
3           Продлить инвалидность с            15745     1244        14501         15244       02.11.1996      05.06.2040
4           Выплачено по ошибке                1         1                                     01.11.1996      01.11.1996
6           Приостановить выплаты до 
               выяснения обстоятельств с       87063     44375       42688         86514       01.02.1996      01.07.2043
-------------------------------------------------------------------------------------------------------------------------------
    TOTAL                                      103378    46068       57310         101775      01.01.1996      01.07.2043

*/
