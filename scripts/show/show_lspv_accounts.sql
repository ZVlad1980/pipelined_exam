select cn.fk_document, cn.cntr_number, cn.fk_scheme, 
       
       acc.*
       --cn.fk_scheme, count(1) cnt
from   contracts cn,
       accounts  acc
where  1=1
and    acc.id = cn.fk_account
and    cn.fk_cntr_type = 6
and    cn.fk_scheme in (1, 2, 3, 4, 5, 6, 8)
--group by rollup(cn.fk_scheme)
/
