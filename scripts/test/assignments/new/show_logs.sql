select *
from   logs
where  logs.fk_log_mark = 1
and    logs.fk_log_token = &fk_pay_order
