      select --assignment_seq.nextval,
             tas.fk_pay_order, --po.fk_document, --fk_doc_with_action
             pa.fk_contract,
             case 
               when pa.fk_scheme in (1, 6) or (pa.fk_scheme = 5 and vp.data_nachisl >= vp.data_perevoda_5_cx) then
                 import_assignments_pkg.get_sspv_id(pa.fk_scheme)
               else pa.fk_debit
             end fk_debit,
             pa.fk_credit,
             case
               when dbl.cnt = 0 then 2 --первичная выплата - всегда начисление пенсии
               else 7 --вторичные выплаты - доплаты!
             end   fk_asgmt_type,
             pa.fk_contragent, --tc.fk_contragent,
             trunc(vp.data_nachisl, 'MM') + dbl.cnt paydate, --vp.data_nachisl,
             vp.summa,
             5000,--GC_PAY_CODE_PENSION, --CDM.PAY_CODES
             coalesce(vp.oplach_dni, 0),
             pa.fk_scheme,
             1 asgmt_state, --ASSIGNMENT_STATES
             pa.fk_contract serv_doc,
             trunc(vp.data_nachisl, 'MM') + dbl.cnt serv_date,
             --
             dbl.cnt,
             vp.tip_vypl,
             vp.data_nachisl,
             vp.ssylka,
             vp.data_op
      from   transform_pa_assignments tas,
             fnd.vypl_pen_v           vp,
             pension_agreements_v     pa,
             lateral(
               select count(1) cnt
               from   fnd.vypl_pen vp2
               where  1 = 1
               and    (vp2.data_op < vp.data_op or (vp2.data_op = vp.data_op and vp2.tip_vypl < vp.tip_vypl) or (vp2.data_op = vp.data_op and vp2.tip_vypl = vp.tip_vypl and vp2.data_nachisl < vp.data_nachisl))
               and    trunc(vp2.data_nachisl, 'MM') = trunc(vp.data_nachisl, 'MM')
               and    vp2.ssylka_fl = vp.ssylka
               and    vp2.data_op <= vp.data_op
             ) dbl
      where  1=1
      and    pa.fk_contract = vp.ref_kodinsz
      and    vp.data_op = tas.date_op
      and    trunc(tas.date_op, 'MM') between to_date(&p_period, 'yyyymmdd') and to_date(&p_period_to, 'yyyymmdd')--p_period
--      and    tas.state = 'N'
    and vp.ssylka = 1508 --2396 --1508
order by paydate
/
/*
01.12.2001  10782 02.11.2001
01.12.2001  17018 02.11.2001
01.12.2001  17997 02.11.2001
01.12.2001  18274 02.11.2001
01.12.2001  25318 02.11.2001
01.12.2001  36680 02.11.2001
01.11.2002  18326 02.10.2002
01.11.2002  36692 02.10.2002

*/
