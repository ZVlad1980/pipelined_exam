select po.*,
       a.*
from   pay_orders  po,
       assignments a
where  po.fk_pay_order_type = 5
and    a.fk_doc_with_action = po.fk_document
order by po.operation_date
/
select po.*,
       d.*
from   pay_orders  po,
       documents   d
where  d.id(+) = po.fk_document
--and    po.operation_date > to_date(20180101, 'yyyymmdd')
and    po.fk_pay_order_type = 2
order by po.operation_date
/
