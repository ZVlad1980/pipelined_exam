PL/SQL Developer Test script 3.0
153
-- Created on 30.06.2018 by V.ZHURAVOV 
declare 
  C_MAX_DATE         constant date   := to_date(20180401, 'yyyymmdd');
  C_ACCOUNT_SSPV     constant number := 10042; --пока так
  F_PAY_ORDER_TYPE   constant number := 5;
  
  
  GC_ASGPC_CODE_LIFE constant number := 5054;   -- начисление, код ПОЖИЗНЕННАЯ ПЕНСИЯ 
  GC_ASG_OP_TYPE     constant number := 2;      -- начисление, код типа для записей начисления пенсии
  
  l_cnt int;
  
  -- Local variables here
  cursor l_docs_cur is
    with docs as (
      select vp.ssylka_doc,
             vp.data_op      date_op
      from   vbz_pay_contragents c,
             fnd.vypl_pen        vp
      where  1=1
      and    vp.data_op < C_MAX_DATE
      and    vp.nom_ips = c.nom_ips
      and    vp.nom_vkl = c.nom_vkl
      group by vp.ssylka_doc, vp.data_op
    )
    select fd.date_op,
           d.id                doc_id,
           d.fk_doc_type
    from   docs                fd,
           fnd.reer_doc_ngpf   rdn,
           documents           d
    where  1=1
    and    d.id = rdn.ref_kodinsz
    and    rdn.ssylka = fd.ssylka_doc
    order by fd.date_op;
  
  
  
  procedure create_assignments(p_doc_id number) is
    l_asg      assignments%rowtype;
    l_asg_cnt  int;
    cursor l_asg_cur is
      select rdn.ref_kodinsz doc_id,
             pa.fk_contract,
             bcn.fk_account  fk_debit,
             cn.fk_account   fk_credit,
             cn.fk_contragent,
             cn.fk_scheme,
             vp.data_nachisl,
             vp.oplach_dni,
             vp.summa amount
      from   vbz_pay_contragents c,
             fnd.vypl_pen        vp,
             fnd.reer_doc_ngpf   rdn,
             pension_agreements  pa,
             contracts           cn,
             contracts           bcn
      where  1=1
      and    bcn.fk_document = pa.fk_base_contract
      and    cn.fk_document = pa.fk_contract
      and    pa.fk_contract = c.fk_contract
      and    rdn.ref_kodinsz = p_doc_id
      and    rdn.ssylka = vp.ssylka_doc
      and    vp.data_op < C_MAX_DATE
      and    vp.nom_ips = c.nom_ips
      and    vp.nom_vkl = c.nom_vkl;
    
  begin
    
    l_asg_cnt := 0;
    for p_asg in l_asg_cur loop
      
      l_asg.fk_doc_with_action := p_asg.doc_id;
      l_asg.fk_doc_with_acct   := p_asg.fk_contract;
      --Для 1 и 6 схем подставляем ССПВ
      l_asg.fk_debit           := nvl(p_asg.fk_debit, case when p_asg.fk_scheme in (1,8) then C_ACCOUNT_SSPV end);
      l_asg.fk_credit          := p_asg.fk_credit;
      l_asg.fk_contragent      := p_asg.fk_contragent;
      l_asg.fk_scheme          := p_asg.fk_scheme;
      l_asg.fk_paycode         := GC_ASGPC_CODE_LIFE;
      --l_asg.comments           := p_asg.comments;
      l_asg.fk_asgmt_type      := GC_ASG_OP_TYPE;
      l_asg.paydate            := p_asg.data_nachisl;
      l_asg.paydays            := p_asg.oplach_dni;
      l_asg.amount             := p_asg.amount;
      l_asg.serv_doc           := p_asg.fk_contract;
      
      assignments_api.push(p_assignment => l_asg);
      
      l_asg_cnt := l_asg_cnt + 1;
      
    end loop;
    
    dbms_output.put_line('Создано начислений по ' || p_doc_id || ': ' || l_asg_cnt);
  end create_assignments;
  
  procedure create_po(p_doc in out nocopy l_docs_cur%rowtype) is
  begin
    dbms_output.put_line('Платежное поручение: ' || p_doc.doc_id);
    
    insert into pay_orders(
      fk_document,
      payment_period,
      operation_date,
      payment_freqmask,
      scheduled_date,
      calculation_date,
      fk_pay_order_type
    ) values (
      p_doc.doc_id,
      trunc(p_doc.date_op, 'MM'),
      p_doc.date_op,
      null,
      null,
      p_doc.date_op,
      F_PAY_ORDER_TYPE
    );
    
    create_assignments(p_doc.doc_id);
    dbms_output.new_line;
  exception
    when others then
      dbms_output.PUT_line('create_po(' || p_doc.doc_id || ' от ' || to_char(p_doc.date_op, 'dd.mm.yyyy') || ') failed');
      raise;
  end create_po;
  
  procedure delete_po(p_doc in out nocopy l_docs_cur%rowtype) is
  begin
    delete from assignments a
    where  a.fk_doc_with_action = p_doc.doc_id;
    delete from pay_orders po
    where  po.fk_document = p_doc.doc_id;
  end;
  
begin
  --dbms_session.reset_package; return;
  -- Test statements here
  assignments_api.init;
  
  l_cnt := 0;
  for d in l_docs_cur loop
    create_po(d);
    --delete_po(d);
    l_cnt := l_cnt + 1;
  end loop;
  
  assignments_api.flush;
  
  dbms_output.put_line('Всего создано/удалено платежных поручений: ' || l_cnt);
  
  commit;
  
end;
0
0
