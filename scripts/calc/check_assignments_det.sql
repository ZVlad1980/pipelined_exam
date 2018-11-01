select pa.fk_contract, pa.effective_date, tc.ssylka_fl, tc.ssylka_ts
from   pension_agreements_v  pa,
       transform_contragents tc
where  1=1
and    pa.fk_base_contract = tc.fk_contract
and    pa.fk_contract = 2773862 --2994825
/--2994825
select *
from   fnd.sp_pen_dog_v pd
where  pd.ssylka = &ssylka
/
select *
from   fnd.vypl_pen vp
where  vp.ssylka_fl = &ssylka
--and    vp.data_op = to_date(20180910, 'yyyymmdd')
order by vp.data_op, vp.data_nachisl
/
select /*+ no_merge*/
       ib.ssylka,--ref_kodinsz             fk_pension_agreement,
       ib.data_nach_vypl,
       ib.data_perevoda_5_cx      transfer_date,
       sum(ib.amount)             amount
from   fnd.sp_ips_balances ib
where  1=1--ib.date_op < p_update_date
and    ib.ssylka = &ssylka
group by ib.ssylka, ib.data_nach_vypl, ib.data_perevoda_5_cx
/
select *
from   fnd.sp_ips_balances b
where  b.ssylka = &ssylka
order by b.date_op
/
select *
from   fnd.sp_izm_pd_v ipd
where  ipd.ssylka_fl = &ssylka
/
select *
from   fnd.sp_ogr_pv_v op
where  op.ssylka_fl = &ssylka
/
select *
from   fnd.sp_invalid_v spi
where  spi.ssylka_fl = &ssylka
