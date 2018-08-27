select asg.amount, pa.*
from   pension_agreements_v pa,
       assignments          asg
where  1=1
and    asg.paydate(+) =  to_date(20180601, 'yyyymmdd')
and    asg.fk_doc_with_acct(+) = pa.fk_contract
and    pa.fk_contract = 2763533--2882227
/
select *
from   fnd.vypl_pen_imp_v vp
where  1=1
and    vp.ref_kodinsz = 2763533
--and    vp.ssylka_fl = 189028
and    vp.data_op = to_date(20180609, 'yyyymmdd')
/
--189028
select *
from   fnd.sp_pen_dog_v pd
where  pd.ssylka = 189028
/
select *
from   fnd.sp_lspv lspv
where  lspv.ssylka_fl = 189028
/
select paa.*
from   pension_agreement_addendums_v paa
where  1=1
and    paa.fk_pension_agreement = 2763533
