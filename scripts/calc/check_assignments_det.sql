select * from ASSIGNMENTS_201809_FND t where t.fk_doc_with_acct = 2796396
/
select pa.fk_contract,
         vp.data_nachisl,
         vp.ssylka_fl,
         vp.data_op,
         vp.tip_vypl,
         sum(vp.summa) amount
  from   fnd.vypl_pen_imp_v    vp,
         transform_contragents tc,
         pension_agreements_v  pa
  where  1=1
  and    pa.effective_date = vp.data_nach_vypl
  and    pa.fk_base_contract = tc.fk_contract
  and    tc.ssylka_fl = vp.ssylka_fl
  and    vp.summa <> 0
  and    vp.data_op = to_date(&actual_date, 'yyyymmdd')
  and    pa.fk_contract = 23539988
  group by pa.fk_contract, vp.data_nachisl, vp.ssylka_fl, vp.data_op, vp.tip_vypl

select pa.fk_contract, pa.effective_date, tc.ssylka_fl, tc.ssylka_ts
from   pension_agreements_v  pa,
       transform_contragents tc
where  1=1
and    pa.fk_base_contract = tc.fk_contract
and    pa.fk_contract = 2806191 --2994825
/--2994825
select *
from   fnd.sp_pen_dog_v pd
where  pd.ssylka = 110606
/

select *
from   fnd.vypl_pen vp
where  vp.data_op = to_date(20180910, 'yyyymmdd')
and    vp.ssylka_fl = 1645664
/
select /*+ no_merge*/
       ib.ssylka,--ref_kodinsz             fk_pension_agreement,
       ib.data_nach_vypl,
       ib.data_perevoda_5_cx      transfer_date,
       sum(ib.amount)             amount
from   fnd.sp_ips_balances ib
where  1=1--ib.date_op < p_update_date
and    ib.ssylka = 1645664
group by ib.ssylka, ib.data_nach_vypl, ib.data_perevoda_5_cx
/
select *
from   fnd.sp_ips_balances b
where  b.ssylka = 11414145
order by b.date_op
/
select *
from   fnd.sp_izm_pd_v ipd
where  ipd.ssylka_fl = 42445
