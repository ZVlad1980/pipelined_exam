select nvl(vp.month, asg.month) month,
       vp.ssylka_fl,
       asg.fk_contragent,
       vp.amount  vp_amount,
       asg.amount asg_amount
from   (
        select trunc(vp.data_nachisl, 'MM') month,
               vp.ssylka_fl,
               sum(vp.summa) amount
        from   fnd.vypl_pen vp
        where  vp.data_op between to_date(&p_start_year || '0101', 'yyyymmdd') and to_date(&p_end_year || '1231', 'yyyymmdd')
        and    vp.ssylka_fl = &ssylka
        group by trunc(vp.data_nachisl, 'MM'),
                 vp.ssylka_fl
       ) vp
      full outer join (
        select trunc(asg.paydate, 'MM') month,
               asg.fk_contragent,
               sum(asg.amount) amount
        from   assignments           asg
        where  1=1
        and    asg.fk_contragent = (select tc.fk_contragent from transform_contragents tc where tc.ssylka_fl = &ssylka) --3036068
        and    asg.fk_doc_with_action in (
                 select pas.fk_pay_order
                 from   transform_pa_assignments pas
                 where  pas.date_op between to_date(&p_start_year || '0101', 'yyyymmdd') and to_date(&p_end_year || '1231', 'yyyymmdd')
               )
        group by trunc(asg.paydate, 'MM'),
               asg.fk_contragent
       ) asg
       on asg.month = vp.month
order by nvl(vp.month, asg.month)
/
select vp.ssylka,
       vp.ref_kodinsz,
       vp.pay_month,
       vp.vp_summa,
       asg.amount
--select *
from   ( 
         select vp.ssylka,
                vp.ref_kodinsz,
                trunc(vp.data_nachisl, 'MM') pay_month,
                sum(vp.summa)                vp_summa
         from   fnd.vypl_pen_v        vp
         where  vp.ssylka = 94155
--         and    trunc(vp.data_nachisl, 'MM') = to_date(19961201, 'yyyymmdd')
         group by vp.ssylka, vp.ref_kodinsz, trunc(vp.data_nachisl, 'MM')
       ) vp,
       lateral(
         select sum(asg.amount) amount
         from   assignments           asg
         where  1=1
         and    trunc(asg.paydate, 'MM') = vp.pay_month
         and    asg.fk_doc_with_acct = vp.ref_kodinsz
         group by asg.fk_doc_with_acct
       )(+) asg
where  vp.vp_summa <> nvl(asg.amount, 0)
/
