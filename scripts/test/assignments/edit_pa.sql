select pa.*, pa.rowid
from   pension_agreements pa
where  pa.fk_contract = 13464073
/
select p.*, p.rowid
from   people p
where  p.fk_contragent = 13464073
