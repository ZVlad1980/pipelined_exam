/*
--check periods
select vp.data_op, count(1)
from   fnd.vypl_pen vp
where  vp.data_op > to_date(20180701, 'yyyymmdd')
group by vp.data_op
*/
--check counts
select 1 state,
       count(vp.ssylka_fl) cnt_total,
       count(distinct vp.ssylka_fl) cnt_ssylka --166655 --vp.ssylka_fl, count(1) cnt, min(vp.data_nachisl) min_data_nachisl, max(vp.data_nachisl) max_data_nachisl
from   fnd.vypl_pen_imp_v    vp
where  1=1
and    vp.data_op = to_date('10.07.2018', 'dd.mm.yyyy')
union all
select case when pa.state = 1 and pa.isarhv = 0 then 1 else 0 end, 
       count(pa.fk_contract) cnt_total,--166655
       count(distinct pa.fk_contract) cnt_contracts--166655
from   fnd.vypl_pen_imp_v    vp,
       transform_contragents tc,
       pension_agreements_v  pa
where  1=1
and    pa.effective_date = vp.data_nach_vypl
and    pa.fk_base_contract = tc.fk_contract
and    tc.ssylka_fl = vp.ssylka_fl
and    vp.data_op = to_date('10.07.2018', 'dd.mm.yyyy')
group by rollup(case when pa.state = 1 and pa.isarhv = 0 then 1 else 0 end)
*/
with w_fnd_vypl as (
	select pa.fk_contract
  from   fnd.vypl_pen_imp_v    vp,
         transform_contragents tc,
         pension_agreements_v  pa
  where  1=1
  and    pa.effective_date = vp.data_nach_vypl
  and    pa.fk_base_contract = tc.fk_contract
  and    tc.ssylka_fl = vp.ssylka_fl
  and    vp.data_op = to_date('10.07.2018', 'dd.mm.yyyy')
)
select *
from   pension_agreements_v pa, --2774296
       w_fnd_vypl           vp
where  1=1
and    vp.fk_contract is null
and    vp.fk_contract(+) = pa.fk_contract
and    not exists (
         select 1
         from   pay_restrictions pr
         where  1=1
         and    to_date(20180701, 'yyyymmdd') between pr.effective_date and coalesce(pr.expiration_date, to_date(20180701, 'yyyymmdd'))
         and    pr.fk_document_cancel is null
         and    pr.fk_doc_with_acct = pa.fk_contract
       )
and    pa.state = 1
and    pa.isarhv = 0
