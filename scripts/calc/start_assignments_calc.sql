declare 
  C_OPERATION_DATE  date := to_date(&date_op, 'yyyymmdd');
  
  l_po_id int;
  l_start date;
  
  -- Функция ищет PO по дате операции, если не находит - создает его
  function create_po return number is
    l_po_id int;
  begin
    begin
      select po.fk_document
      into   l_po_id
      from   pay_orders po
      where  po.fk_pay_order_type = 5
      and    po.operation_date = C_OPERATION_DATE
      and    rownum = 1;
    
    exception
      when no_data_found then
        l_po_id := document_seq.nextval();
        
        insert all
          when 1=1 then
            into documents(id, doc_date, title, is_accounting_doc)
            values(doc_id, operation_date, doc_title, 0)
          when 1=1 then
            into pay_orders(fk_document, payment_period, operation_date, payment_freqmask, scheduled_date, fk_pay_order_type)
            values(doc_id, payment_period, operation_date, payment_freqmask, operation_date, fk_pay_order_type)
          select l_po_id doc_id,
                 'Тестовое начисление' doc_title,
                 trunc(C_OPERATION_DATE, 'MM') payment_period,
                 C_OPERATION_DATE              operation_date,
                 '00001111'                    payment_freqmask,
                 5                             fk_pay_order_type
          from   dual;
        commit;
        
        dbms_output.put_line('PO created: ' || l_po_id);
    end;

    return l_po_id;

  end create_po;
  
  procedure ei(p_cmd varchar2) is
  begin
    execute immediate p_cmd;
  exception
    when others then
      log_pkg.put(p_message => 'Failed ' || p_cmd || chr(10) || ': ' || sqlerrm);
  end;
  
begin
  --dbms_session.reset_package; return;
  --
  l_po_id := create_po();
  dbms_output.put_line('Assignments with PO: ' || l_po_id || ', operation date: ' || to_char(C_OPERATION_DATE, 'dd.mm.yyyy'));
  
  delete from pay_order_filters where fk_pay_order = l_po_id;
  commit;

  log_pkg.enable_output;
  l_start := sysdate;
  log_pkg.put('Start at ' || to_char(l_start, 'dd.mm.yyyy hh24:mi:ss'));
  begin
    pay_gfnpo_pkg.calc_assignments(p_pay_order_id => l_po_id, p_oper_id => 0);
    ei('drop table assignments_gf');
    ei('create table assignments_gf as
      select *
      from   assignments asg
      where  asg.fk_doc_with_action = ' || l_po_id
    );
  exception
    when others then
      log_pkg.show_errors_all;
  end;
  log_pkg.put('Complete at ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss'));
  log_pkg.put(' Duration: ' || to_char(round((sysdate - l_start) * 86400, 3)) || ' sec');
end;
