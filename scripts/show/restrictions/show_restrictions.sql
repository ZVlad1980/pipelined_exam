select fs.path, fs.old_file_name, d.title, pr.*
from   pay_restrictions pr,
       documents        d,
       filestorages     fs
where  pr.fk_doc_with_acct in (
         select cn.fk_document
         from   contracts cn
         where  cn.fk_cntr_type = 6
         and    cn.fk_scheme in (1,2,3,4,5,6,8)
       )
and    d.id = pr.fk_doc_with_action
and    fs.id = d.Fk_File
/
select fs.path, fs.old_file_name, d.title, pr.*
from   pay_restrictions pr,
       documents        d,
       filestorages     fs
where  pr.fk_doc_with_acct in (
         select cn.fk_document
         from   contracts cn
         where  cn.fk_cntr_type = 6
         and    cn.fk_scheme in (1,2,3,4,5,6,8)
       )
and    d.id = pr.fk_doc_with_action
and    fs.id = d.Fk_File
