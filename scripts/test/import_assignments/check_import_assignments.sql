select vp.ssylka_fl, sum(vp.summa) amount
from   fnd.vypl_pen_imp_v vp
where  vp.data_op between to_date(&p_start_year || '0101', 'yyyymmdd') and to_date(&p_end_date, 'yyyymmdd')
group by vp.ssylka_fl
minus
select tc.ssylka_fl,
       sum(asg.amount) amount
from   assignments           asg,
       pension_agreements    pa,
       transform_contragents tc
where  1=1
and    tc.fk_contract = pa.fk_base_contract
and    pa.fk_contract = asg.fk_doc_with_acct
and    asg.fk_doc_with_action in (
         select pas.fk_pay_order
         from   transform_pa_assignments pas
         where  pas.date_op between to_date(&p_start_year || '0101', 'yyyymmdd') and to_date(&p_end_date, 'yyyymmdd')
       )
group by tc.ssylka_fl
/
