--ImportPA_20180724081643
select *
from   err$_imp_documents
where  ora_err_tag$ = &l_err_tag
/
select *
from   err$_imp_contracts
where  ora_err_tag$ = &l_err_tag
/
select *
from   err$_imp_pension_agreements
where  ora_err_tag$ = &l_err_tag
/
