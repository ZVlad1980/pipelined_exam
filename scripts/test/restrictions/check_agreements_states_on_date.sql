select vp.data_nachisl, count(1) cnt
---select *
from   fnd.vypl_pen_imp_v vp
where  vp.data_op = to_date(20180810, 'yyyymmdd')
--and    vp.data_nachisl = to_date('01.09.2016', 'dd.mm.yyyy')
group by vp.data_nachisl
/
--Основной запрос! Проверяет наличие ограничений за начисленный период
select --pa.state, pa.isarhv, count(1) cnt /*
       --count(1) /*
       pa.fk_contract,
       pa.fk_base_contract,
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
         and    pr.remarks like '%озврат%'
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
--Проверка корректности формирования списка на выплату в GF
select ag.creation_date, pd.ssylka, pa.period_code, pa.*
from   agreements_list_t     ag,
       pension_agreements    pa,
       transform_contragents tc,
       fnd.sp_pen_dog_v      pd
where  1=1
and    not exists (
         select 1
         from   pay_restrictions pr
         where  pr.fk_doc_with_acct = ag.fk_contract
         and    to_date(20180801, 'yyyymmdd') between pr.effective_date and nvl(pr.expiration_date, to_date(20180801, 'yyyymmdd'))
       )
and    not exists (
         select 1
         from   fnd.vypl_pen vp
         where  1=1
         --and    vp.data_nachisl = to_date(20180801, 'yyyymmdd')--
         and    vp.data_op = to_date(20180810, 'yyyymmdd')
         and    vp.ssylka_fl = pd.ssylka
       )
and    pd.data_nach_vypl = pa.effective_date
and    pd.ssylka = tc.ssylka_fl
and    tc.fk_contract = pa.fk_base_contract
and    pa.fk_contract = ag.fk_contract
--and    ag.period_code = 1
and    pa.creation_date < to_date(20180810, 'yyyymmdd')
/
--Детализация
select *
from   fnd.sp_ogr_pv_v op
where  op.ssylka_fl = &ssylka --981899
/
select *
from   fnd.sp_ogr_pv_rev_v op
where  op.ssylka_fl = &ssylka
/
select *
from   fnd.sp_ogr_pv_imp_v op
where  op.ssylka_fl = &ssylka --8606
/
select *
from   fnd.vypl_pen vp
where  vp.ssylka_fl = &ssylka
--and    vp.data_op = to_date(20180810, 'yyyymmdd')
order by vp.data_nachisl, vp.data_op
/
select *
from   pay_restrictions pr
where  pr.fk_doc_with_acct in(
         select pa.fk_contract
          from   pension_agreements_v pa
          where  pa.fk_base_contract = &fk_base_contract
       )
/
select *
from   fnd.sp_pen_dog_imp_v pd
where  pd.ssylka = &ssylka
/
select *
from   pension_agreements_v pa
where  pa.fk_base_contract = &fk_base_contract
