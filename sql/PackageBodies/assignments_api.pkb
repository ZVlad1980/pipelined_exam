create or replace package body assignments_api is
  
  GC_UNIT_NAME   constant varchar2(32) := $$PLSQL_UNIT;
  
  GC_ASG_CHUNK_SIZE  constant number := 10000;
  
  type g_assignments_typ is table of assignments%rowtype;
  g_assignments g_assignments_typ;
  
  procedure init is
  begin
    g_assignments := g_assignments_typ();
  end init;
  
  procedure flush is
  begin
    forall i in 1..g_assignments.count
      insert into assignments(
        id,
        fk_doc_with_action,
        fk_doc_with_acct,
        fk_debit,
        fk_credit,
        fk_asgmt_type,
        fk_contragent,
        paydate,
        amount,
        amount_detail,
        paytax,
        fk_paycode,
        paydays,
        fk_scheme,
        comments,
        asgmt_state,
        fk_created,
        fk_prepared,
        fk_pay_payment,
        fk_pay_refund_type,
        isexists,
        isauto,
        iscancel,
        serv_doc,
        serv_date,
        creation_date,
        fk_registry,
        direction
      ) values (
        assignment_seq.nextval,
        g_assignments(i).fk_doc_with_action,
        g_assignments(i).fk_doc_with_acct,
        g_assignments(i).fk_debit,
        g_assignments(i).fk_credit,
        g_assignments(i).fk_asgmt_type,
        g_assignments(i).fk_contragent,
        g_assignments(i).paydate,
        g_assignments(i).amount,
        g_assignments(i).amount_detail,
        g_assignments(i).paytax,
        g_assignments(i).fk_paycode,
        g_assignments(i).paydays,
        g_assignments(i).fk_scheme,
        g_assignments(i).comments,
        g_assignments(i).asgmt_state,
        g_assignments(i).fk_created,
        g_assignments(i).fk_prepared,
        g_assignments(i).fk_pay_payment,
        g_assignments(i).fk_pay_refund_type,
        g_assignments(i).isexists,
        g_assignments(i).isauto,
        g_assignments(i).iscancel,
        g_assignments(i).serv_doc,
        g_assignments(i).serv_date,
        g_assignments(i).creation_date,
        g_assignments(i).fk_registry,
        g_assignments(i).direction
      ) log errors into err$_assignments (GC_UNIT_NAME) reject limit unlimited;
  /*exception
    when others then
      fix_exception($$PLSQL_LINE, 'flush_assignments failed');
      raise;*/
  end flush;
  
  /**
   *
   */
  procedure push(
    p_assignment assignments%rowtype
  ) is
  begin
    g_assignments.extend;
    g_assignments(g_assignments.count) := p_assignment;
    
    g_assignments(g_assignments.count).amount        := nvl(g_assignments(g_assignments.count).amount,        0);
    g_assignments(g_assignments.count).amount_detail := nvl(g_assignments(g_assignments.count).amount_detail, 0);
    g_assignments(g_assignments.count).paytax        := nvl(g_assignments(g_assignments.count).paytax,        0);
    g_assignments(g_assignments.count).paydays       := nvl(g_assignments(g_assignments.count).paydays,       0);
    g_assignments(g_assignments.count).asgmt_state   := nvl(g_assignments(g_assignments.count).asgmt_state,   0);
    g_assignments(g_assignments.count).isexists      := nvl(g_assignments(g_assignments.count).isexists,      0);
    g_assignments(g_assignments.count).isauto        := nvl(g_assignments(g_assignments.count).isauto,        0);
    g_assignments(g_assignments.count).iscancel      := nvl(g_assignments(g_assignments.count).iscancel,      0);
    g_assignments(g_assignments.count).creation_date := nvl(g_assignments(g_assignments.count).creation_date, sysdate);
    g_assignments(g_assignments.count).direction     := nvl(g_assignments(g_assignments.count).direction,     1);
    
    if g_assignments.count >= GC_ASG_CHUNK_SIZE then
      flush;
      init;
    end if;
  /*exception
    when others then
      fix_exception($$PLSQL_LINE, 'push_assignment failed');
      raise;*/
  end push;
  
  
end assignments_api;
/
