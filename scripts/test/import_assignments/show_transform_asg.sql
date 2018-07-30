select t.*,
       (
        select count(1)
        from   pay_orders po
        where  po.fk_document = t.fk_pay_order
       ) pay_cnt,
       t.rowid
from   transform_pa_assignments t
order by t.date_op desc
--23464490
/
select *
from   assignments asg
where  asg.fk_doc_with_action in (23464490, 23464491, 23464492)
/*
with w_sspv as (
select /*+ materialize a.fk_scheme,
       a.id fk_account
from   accounts_sspv_v a
)
select tas.import_id,
       po.fk_document, --fk_doc_with_action
       pa.fk_contract,
       case 
         when vp.shema_dog in (1, 6) or (vp.shema_dog = 5 and vp.data_nachisl >= vp.data_perevoda_5_cx) then
           sspv.fk_account
         else pa.fk_debit
       end fk_debit,
       pa.fk_credit,
       case 
         when vp.tip_vypl in (1, 2, 5, 7, 90, 91, 92, 95, 97, 101, 111) then 2
         else 7
       end fk_asgmt_type, --CDM.ASSIGNMENT_TYPES
       tc.fk_contragent,
       vp.data_nachisl,
       vp.summa,
       5000, --CDM.PAY_CODES
       vp.oplach_dni,
       pa.fk_scheme,
       1 asgmt_state --ASSIGNMENT_STATES
from   transform_pa_assignments tas,
       pay_orders               po,
       fnd.vypl_pen_v           vp,
       transform_contragents    tc,
       pension_agreements_v     pa,
       w_sspv                   sspv
where  1=1
and    sspv.fk_scheme(+) = vp.shema_dog
and    pa.effective_date = vp.data_nach_vypl
and    pa.fk_base_contract = tc.fk_contract
and    tc.ssylka_fl = vp.ssylka
and    vp.data_op = tas.date_op
and    po.payment_period = to_date(19960301, 'yyyymmdd')
and    po.fk_document = tas.fk_pay_order
and    tas.state = 'N'
and    tas.import_id = '20180726135724'
/*
insert into assignments(
  id,
  fk_doc_with_action,
  fk_doc_with_acct,
  fk_debit,
  fk_credit,
  fk_asgmt_type,
  fk_contragent,
  paydate,
  amount,
  fk_paycode,
  paydays,
  fk_scheme,
  comments,
  asgmt_state,
  fk_created,
  fk_prepared,
  fk_pay_payment,
  fk_pay_refund_type,
  isexists,
  isauto,
  iscancel,
  serv_doc,
  serv_date,
  creation_date,
  fk_registry,
  direction
)
*/
--assignment_seq.nextval
