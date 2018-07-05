PL/SQL Developer Test script 3.0
111
-- Created on 30.06.2018 by V.ZHURAVOV 
declare 
  C_SSYLKA_DOC       constant number := 818763;
  C_NOM_VKL          constant number := 50;
  
  C_PAY_ORDER_TYPE   constant number := 5;
  
  
  l_cnt int;
  
  -- Local variables here
  cursor l_po_cur is
    select d.id                fk_document,
           rdn.ssylka          ssylka_doc,
           (select max(vp.data_op)
            from   fnd.vypl_pen vp
            where  vp.ssylka_doc = rdn.ssylka
           ) pay_date,
           d.fk_doc_type
    from   fnd.reer_doc_ngpf   rdn,
           documents           d
    where  1=1
    and    d.id = rdn.ref_kodinsz
    and    rdn.ssylka = C_SSYLKA_DOC;
  
  procedure create_po(p_doc in out nocopy l_po_cur%rowtype) is
  begin
    dbms_output.put_line('Платежное поручение: ' || p_doc.fk_document || ', ssylka_doc = ' || p_doc.ssylka_doc);
    
    insert into pay_orders(
      fk_document,
      payment_period,
      operation_date,
      payment_freqmask,
      scheduled_date,
      calculation_date,
      fk_pay_order_type
    ) values (
      p_doc.fk_document,
      trunc(p_doc.pay_date, 'MM'),
      p_doc.pay_date,
      '00000011',
      null,
      p_doc.pay_date,
      C_PAY_ORDER_TYPE
    );
    
    insert into pay_order_filters(
      fk_pay_order,
      filter_code,
      filter_value
    ) select p_doc.fk_document,
             'CONTRACT',
             c.fk_document
      from   contracts  c
      where  c.fk_contragent in (
               select sfl.gf_person
               from   fnd.vypl_pen         vp,
                      fnd.sp_fiz_lits      sfl
               where  1=1
               and    sfl.ssylka = vp.ssylka_fl
               and    vp.nom_vkl = C_NOM_VKL
               and    vp.ssylka_doc = p_doc.ssylka_doc
             )
      and    c.fk_cntr_type = 6
      and    c.fk_document = 13464073;

    dbms_output.put_line('Добавлено контрактов: ' || sql%rowcount);
    
    
    dbms_output.new_line;
  exception
    when others then
      dbms_output.PUT_line('create_po(' || p_doc.fk_document || ' от ' || to_char(p_doc.pay_date, 'dd.mm.yyyy') || ') failed');
      raise;
  end create_po;
  
  procedure delete_po(p_doc in out nocopy l_po_cur%rowtype) is
  begin
    
    delete from assignments a
    where  a.fk_doc_with_action = p_doc.fk_document;
  
    delete from pay_order_filters a
    where  a.fk_pay_order = p_doc.fk_document;
    
    delete from pay_orders po
    where  po.fk_document = p_doc.fk_document;
    
  end;
  
begin
  --dbms_session.reset_package; return;
  -- Test statements here
  --assignments_api.init;
  
  l_cnt := 0;
  for d in l_po_cur loop
    delete_po(d);
    create_po(d);
    l_cnt := l_cnt + 1;
  end loop;
  
  
  --assignments_api.flush;
  
  dbms_output.put_line('Всего создано/удалено платежных поручений: ' || l_cnt);
  
  --commit;
  
end;
0
0
