select t.start_id,
       t.end_id,
       t.created_at, 
       t.rows_cnt, 
       t.duration,
       round(t.duration / t.rows_cnt, 3) per_row,
       t.session_id
from   pay_gfnpo_logs t 
order by t.created_at
/
--session_id, count(1)
