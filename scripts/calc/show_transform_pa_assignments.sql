select t.state, min(t.date_op) min_date_op, max(t.date_op) max_date_op, min(t.creation_date) creation_date, max(t.last_update_date) last_update_date, count(1) cnt
from   transform_pa_assignments t
group by t.state
order by t.state
/
select t.pay_month, t.creation_date, t.last_update_date,
       lag(t.last_update_date)over(order by t.pay_month) prev_update_date,
       round((t.last_update_date - lag(t.last_update_date)over(order by t.pay_month)) * 24*60, 2) duration_min
from   (
select trunc(t.date_op, 'MM') pay_month, min(t.creation_date) creation_date, max(t.last_update_date) last_update_date
from   transform_pa_assignments t
group by trunc(t.date_op, 'MM')
) t
where t.last_update_date is not null
order by t.pay_month
/
select t.*, t.rowid
from   transform_pa_assignments t
--where  t.date_op > to_date(20161101, 'yyyymmdd')--t.state = 'E'
order by t.date_op desc
/
23890259
23890258
create table assignments_201807 as
select * 
--delete 
from assignments asg where asg.fk_doc_with_action in (23890257, 23890256)
/
with w_po as (
select tpa.ssylka_doc, tpa.fk_pay_order, tpo.operation_date, tpo.payment_period,
       min(tpa.date_op) min_date_op, max(tpa.date_op) max_date_op,
       count(distinct tpa.date_op) cnt_date_op
from   transform_pa_assignments tpa,
       transform_po             tpo
where  tpa.ssylka_doc is not null
and    tpo.fk_document  = tpa.fk_pay_order
group by tpa.ssylka_doc, tpa.fk_pay_order, tpo.operation_date, tpo.payment_period
)
select po.ssylka_doc, po.fk_pay_order, po.operation_date, 
       po.payment_period, po.min_date_op, po.max_date_op,
       po.cnt_date_op,
       count(1) cnt_assignments,
       min(asg.paydate) min_paydate,
       max(asg.paydate) max_paydate
from   w_po po,
       assignments asg
where  asg.fk_doc_with_action = po.fk_pay_order
group by po.ssylka_doc, po.fk_pay_order, po.operation_date, 
         po.payment_period, po.min_date_op, po.max_date_op, 
         po.cnt_date_op
order by po.payment_period
