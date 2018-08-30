select cn.fk_scheme                                                   fk_scheme,
       sum(case when tc.ssylka_fl is null then 1 else 0 end)          tc_cnt,
       count(1)                                                       total_cnt,
       sum(case when pa.state = 1 then 1 else 0 end)                  active_state_cnt,
       sum(case when pa.effective_date < sysdate then 1 else 0 end)   actual_cnt,
       sum(case when pa.isarhv <> 0 then 1 else 0 end)                arh_cnt,
       sum(case when bcn.fk_account is null then 0 else 1 end)        with_ips_cnt,
       sum(case when cn.fk_account is null then 0 else 1 end)         with_lspv_cnt,
       min(cn.cntr_date)                                              min_cntr_date,
       max(cn.cntr_date)                                              max_cntr_date,
       min(pa.creation_date)                                          min_creation_date,
       max(pa.creation_date)                                          max_creation_date
from   pension_agreements pa,
       contracts          cn,
       contracts          bcn,
       transform_contragents tc
where  1=1
and    tc.fk_contract(+) = pa.fk_base_contract
and    bcn.fk_document = pa.fk_base_contract
and    cn.fk_scheme not in (7, 9, 10)
and    cn.fk_company <> 1001
and    cn.fk_document = pa.fk_contract
group by cn.fk_scheme
order by cn.fk_scheme
/
