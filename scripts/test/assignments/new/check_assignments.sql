select pd.ref_kodinsz, trunc(vp.data_nachisl, 'MM') paydate, sum(vp.summa) amount
from   fnd.vypl_pen   vp,
       fnd.sp_pen_dog pd
where  1=1
and    pd.ssylka(+) = vp.ssylka_fl
and    vp.data_op = to_date(20180609, 'yyyymmdd')
group by pd.ref_kodinsz, trunc(vp.data_nachisl, 'MM')
minus
select asg.fk_doc_with_acct, trunc(asg.paydate, 'MM') paydate, sum(asg.amount) amount
from   assignments asg
where  asg.fk_doc_with_action = 23513113
group by asg.fk_doc_with_acct, trunc(asg.paydate, 'MM')
/
