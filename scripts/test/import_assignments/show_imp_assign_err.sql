--truncate table err$_imp_assignments
select distinct tc.ssylka_fl, ea.fk_doc_with_acct, pa.fk_credit/*
       po.payment_period date_op, tc.ssylka_fl, to_date(ea.paydate) data_nachisl, 
       ea.fk_doc_with_acct, 
       ea.serv_doc,
       ea.serv_date,
       ea.* --*/
from   err$_imp_assignments   ea,
       pay_orders             po,
       transform_contragents  tc,
       pension_agreements_v   pa
where  tc.fk_contragent = ea.fk_contragent
and    po.fk_document = ea.fk_doc_with_action
and    pa.fk_contract(+) = ea.fk_doc_with_acct
and    ea.ora_err_mesg$ like 'ORA-01400: cannot insert NULL into ("GAZFOND"."ASSIGNMENTS"."FK_DEBIT%' /*like 'CreateAccounts_20180727123452%'--#19990501'
and    ea.ora_err_mesg$ like 'ORA-01400: cannot insert NULL into ("GAZFOND"."ASSIGNMENTS"."FK_CREDIT")%'
/
/*
1996 - CreateAccounts_20180727103436#19961101

*/
select *
from   assignments asg
where  asg.fk_doc_with_acct = 6437573

/
select *
from   fnd.vypl_pen_v vp
where  vp.ssylka = 39628
and    vp.data_op between to_date('01.04.1999', 'dd.mm.yyyy') and last_day(to_date('01.12.1999', 'dd.mm.yyyy'))
and    vp.data_nachisl >= to_date('01.04.1999', 'dd.mm.yyyy')
/
select *
from   fnd.vypl_pen_v vp
where  1=1--vp.ssylka = 14432
and    vp.data_op between to_date('01.01.1997', 'dd.mm.yyyy') and to_date('31.01.1997', 'dd.mm.yyyy')
and    vp.data_nachisl = to_date('01.01.1997', 'dd.mm.yyyy')
