declare 
  l_po_id  int := 23908544;
  
  l_start date;
  
  -- Local variables here
  function create_po return number is
    l_po_id int;
    l_err_tag varchar2(50);
  begin
    
    l_po_id := document_seq.nextval();
    l_err_tag := 'createPO_test_' || to_char(sysdate, 'yyyymmddhh24miss');
    
    insert all
      when 1=1 then
        into documents(id, doc_date, title, is_accounting_doc)
        values(doc_id, operation_date, doc_title, 0)
        log errors into ERR$_IMP_DOCUMENTS (l_err_tag) reject limit unlimited
      when 1=1 then
        into pay_orders(fk_document, payment_period, operation_date, payment_freqmask, scheduled_date, fk_pay_order_type)
        values(doc_id, payment_period, operation_date, payment_freqmask, operation_date, fk_pay_order_type)
        log errors into ERR$_IMP_PAY_ORDERS (l_err_tag) reject limit unlimited
      select l_po_id doc_id,
             'Тестовое начисление' doc_title,
             to_date(20180901, 'yyyymmdd') payment_period,
             to_date(20180910, 'yyyymmdd') operation_date,
             '00001111'                    payment_freqmask,
             5                             fk_pay_order_type
      from   dual;
    
    commit;
    dbms_output.put_line('PO created: ' || l_po_id);
    return l_po_id;
  end;
begin
  --dbms_session.reset_package; return;
    
  delete from pay_order_filters where fk_pay_order = l_po_id;
  commit;
  -- если нужно создать PO:  
  --dbms_output.put_line(create_po()); return;
  
  log_pkg.enable_output;
  l_start := sysdate;
  l_start := sysdate;
  log_pkg.put('Start at ' || to_char(l_start, 'dd.mm.yyyy hh24:mi:ss'));
  begin
    pay_gfnpo_pkg.calc_assignments(p_pay_order_id => l_po_id, p_oper_id => 0);
  exception
    when others then
      log_pkg.show_errors_all;
  end;
  log_pkg.put('Complete at ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
  log_pkg.put(' Duration: ' || to_char(round((sysdate - l_start) * 86400, 3)) || ' sec');
end;
