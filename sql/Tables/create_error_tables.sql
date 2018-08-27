declare
  l_list_tbl sys.odcivarchar2list := 
    sys.odcivarchar2list(
      'ASSIGNMENTS                    ',
      'DOCUMENTS                      ERR$_IMP_DOCUMENTS',
      'CONTRACTS                      ERR$_IMP_CONTRACTS',
      'PENSION_AGREEMENTS             ERR$_IMP_PENSION_AGREEMENTS',
      'ACCOUNTS                       ERR$_IMP_ACCOUNTS',
      'PAY_ORDERS                     ERR$_IMP_PAY_ORDERS',
      'ASSIGNMENTS                    ERR$_IMP_ASSIGNMENTS',
      'PAY_PORTFOLIOS                 ERR$_IMP_PAY_PORTFOLIOS',
      'PAY_DECISIONS                  ERR$_IMP_PAY_DECISIONS',
      'PENSION_AGREEMENT_ADDENDUMS    ERR$_PENSION_AGREEMENT_ADDEND',
      'PAY_RESTRICTIONS               ERR$_IMP_PAY_RESTRICTIONS'
    );

  procedure create_err_table(
    p_table_name   varchar2,
    p_err_tbl_name varchar2 default null
  ) is
    e_exists_tbl exception;
    pragma exception_init(e_exists_tbl, -955);
  begin
    --execute immediate 'drop table ' || nvl(p_err_tbl_name, 'ERR$_' || p_table_name);
    dbms_output.put('Create ' || p_err_tbl_name || ' error table for ' || p_table_name || ' ... ');
    DBMS_ERRLOG.CREATE_ERROR_LOG(
      dml_table_name => p_table_name,
      err_log_table_name =>  p_err_tbl_name
    ); --'');
    dbms_output.put_line('Ok');
  exception
    when e_exists_tbl then
      dbms_output.put_line('Exists');
    when others then
      dbms_output.put_line('Error: ' || sqlerrm);
  end create_err_table;
  
begin
  for i in 1..l_list_tbl.count loop
    create_err_table(
      p_table_name   => regexp_substr(l_list_tbl(i), '[^ ]+', 1, 1),
      p_err_tbl_name => regexp_substr(l_list_tbl(i), '[^ ]+', 1, 2)
    );
  end loop;
end;
/
create index err$_assignments_ix on err$_assignments(fk_doc_with_action) tablespace GFNDINDX
/
