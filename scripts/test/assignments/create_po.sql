declare
  l_po_id int;
  l_err_tag varchar2(50);
begin
  
  return;

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
           to_date(20180701, 'yyyymmdd') payment_period,
           to_date(20180710, 'yyyymmdd') operation_date,
           '00001111'                    payment_freqmask,
           5                             fk_pay_order_type
    from   dual;
  
  commit;
  
  dbms_output.put_line('PO created: ' || l_po_id);
  --23601738
end;