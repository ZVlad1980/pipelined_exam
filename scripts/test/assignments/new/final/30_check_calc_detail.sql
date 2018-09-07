select vp.ssylka_fl, vp.data_nachisl, vp.summa, vp.tip_vypl, vp.data_op
from   fnd.vypl_pen           vp
where  1=1
and    vp.ssylka_fl in (
         select paf.ssylka_fl
         from   pension_agreements_fnd paf
         where  paf.fk_contract = &fk_pa
       )
order by vp.data_nachisl desc, vp.data_op
/
select paf.fk_contract, vp.data_nachisl, vp.summa, vp.tip_vypl
from   pension_agreements_fnd paf,
       fnd.vypl_pen           vp
where  1=1
and    vp.data_op = paf.data_op
and    vp.ssylka_fl = paf.ssylka_fl
and    vp.data_nachisl = paf.data_nachisl
and    paf.fk_contract = &fk_pa
order by vp.data_nachisl desc
/
select asg.fk_doc_with_acct, asg.paydate, asg.amount, asg.*
from   assignments asg
where  asg.fk_doc_with_action = 23855397
and    asg.fk_doc_with_acct = &fk_pa
order by asg.paydate desc
