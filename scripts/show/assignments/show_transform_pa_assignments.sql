select t.state, min(t.date_op) min_date_op, max(t.date_op) max_date_op, max(t.creation_date) creation_date, max(t.last_update_date) last_update_date, count(1) cnt
from   transform_pa_assignments t
group by t.state
order by t.state
/
select t.*, t.rowid
from   transform_pa_assignments t
where  t.date_op > to_date(20160401, 'yyyymmdd')--t.state = 'E'
order by t.date_op
/
select *
from   assignments asg
where  asg.fk_doc_with_action in (23512411,23512950)
