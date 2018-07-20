declare
  l_list_tbl sys.odcivarchar2list := 
    sys.odcivarchar2list(
      'assignments'
    );

  procedure create_err_table(p_table_name varchar2) is
    e_exists_tbl exception;
    pragma exception_init(e_exists_tbl, -955);
  begin
    dbms_output.put('Create error table for ' || p_table_name || ' ... ');
    DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name => p_table_name); --'');
    dbms_output.put_line('Ok');
  exception
    when e_exists_tbl then
      dbms_output.put_line('Exists');
    when others then
      dbms_output.put_line('Error: ' || sqlerrm);
  end create_err_table;
  
begin
  for i in 1..l_list_tbl.count loop
    create_err_table(p_table_name => l_list_tbl(i));
  end loop;
end;
/
create index err$_assignments_ix on err$_assignments(fk_doc_with_action)
/
begin
  dbms_errlog.create_error_log(dml_table_name => 'DOCUMENTS',          err_log_table_name => 'ERR$_IMP_DOCUMENTS');
  dbms_errlog.create_error_log(dml_table_name => 'CONTRACTS',          err_log_table_name => 'ERR$_IMP_CONTRACTS');
  dbms_errlog.create_error_log(dml_table_name => 'PENSION_AGREEMENTS', err_log_table_name => 'ERR$_IMP_PENSION_AGREEMENTS');
end;
