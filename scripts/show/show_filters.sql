select filter_value
              from   pay_order_filters pof
              where  pof.filter_code = 'CONTRACT'
              and    pof.fk_pay_order = 23159064
/
select pa.*
from   contracts c,
       pension_agreements pa
where  c.fk_document = 22880500
and    pa.fk_contract = c.fk_document
