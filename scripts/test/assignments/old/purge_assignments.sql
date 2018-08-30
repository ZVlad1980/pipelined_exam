select asg.fk_doc_with_action, count(1)
--delete
from   assignments asg
where  asg.fk_doc_with_action in (23513113, 23512394)
group by rollup(asg.fk_doc_with_action)
/*
23512394    4016
23513113  168117
TOTAL     172133
*/
