--CreateAccounts_20180724124241
-- truncate table ERR$_ACCOUNTS
select *
from   ERR$_ACCOUNTS ea
where  ea.ora_err_tag$ = &l_err_tag;
/
accounts
/
