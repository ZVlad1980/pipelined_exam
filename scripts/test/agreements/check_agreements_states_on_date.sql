select vp.data_nachisl, count(1) cnt
---select *
from   fnd.vypl_pen_imp_v vp
where  vp.data_op = to_date(20180810, 'yyyymmdd')
--and    vp.data_nachisl = to_date('01.09.2016', 'dd.mm.yyyy')
group by vp.data_nachisl
/
--Основной запрос!
select --pa.state, pa.isarhv, count(1) cnt /*
       --count(1) /*
       pa.fk_contract,
       pa.state,
       pa.isarhv,
       vp.* --*/
from   fnd.vypl_pen_imp_v    vp,
       transform_contragents tc,
       pension_agreements    pa
where  1=1
and    not exists (
         select 1
         from   pay_restrictions pr
         where  pr.fk_document_cancel is null
         and    vp.data_nachisl between pr.effective_date and nvl(pr.expiration_date, vp.data_nachisl)
         and    pr.fk_doc_with_acct = pa.fk_contract
         and    pr.remarks like '%Возврат-сч%'
       )
and    exists (
         select 1
         from   pay_restrictions pr
         where  pr.fk_document_cancel is null
         and    vp.data_nachisl between pr.effective_date and nvl(pr.expiration_date, vp.data_nachisl)
         and    pr.fk_doc_with_acct = pa.fk_contract
       )
--and    not(pa.state = 1 and pa.isarhv = 0)
and    pa.effective_date(+) = vp.data_nach_vypl
and    pa.fk_base_contract(+) = tc.fk_contract
and    tc.ssylka_fl(+) = vp.ssylka_fl
and    vp.data_op = to_date(20180810, 'yyyymmdd')
/
select *
from   fnd.sp_ogr_pv_v op
where  op.ssylka_fl = &ssylka --981899
/
select *
from   fnd.sp_ogr_pv_imp_v op
where  op.ssylka_fl = &ssylka
/
select *
from   fnd.vypl_pen vp
where  vp.ssylka_fl = &ssylka
--and    vp.data_op = to_date(20180810, 'yyyymmdd')
order by vp.data_nachisl, vp.data_op
/
select *
from   pay_restrictions pr
where  pr.fk_doc_with_acct = 2814005
/
