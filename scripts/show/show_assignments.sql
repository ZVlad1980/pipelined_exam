select a.*, a.rowid
       --count(1)
--delete
from   assignments a
where  1=1
--and    a.fk_doc_with_action = 23159079
and    a.fk_doc_with_acct = 13464073
order by a.paydate
/
--delete from err$_assignments
select *
from   err$_assignments
