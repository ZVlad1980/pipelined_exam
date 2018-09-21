create or replace package pay_gfnpo_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 29.06.2018 11:08:41
  -- Purpose : 


  /**
   * WRAP ������� ��� ��������� calc_assignments (������������ - ��������� ���.API (��. PAY_GFOPS_PKG)
   * ��������� ������� ���������� ������
   */
  -- 
  function Fill_Charges_by_PayOrder( pPayOrder in number, pOperID in number ) RETURN NUMBER;
  
  /**
   * WRAP ������� ��� purge_assignments - ��������� ���.API (��. PAY_GFOPS_PKG)
   * ������� ������ ��� ������ �������� �� ��������� ������������
   * ������� ����������
   */
  function Wipe_Charges_by_PayOrder( pPayOrder in number, pOperID in number, pDoNotCommit in number default 0 ) RETURN NUMBER;
  
  /**
   * ��������� ������ �������� ��� 
   */
  procedure purge_hash_pkg;
  
  /**
   * ������� ������� ������� ������ �� �������� �����
   *   ���������� ��� ���������� ������, ���� � ������ ������ ���� ������� ����������� ��� ������� ���������� ������
   * ��� ������ ������������� - ��������� ��� (purge_pension_hash)
   */
  function get_pension(
    p_fk_pension_agreement number, 
    p_month_date           date
  ) return number deterministic
  parallel_enable;
  
  /**
   * ������� ���������� ���������� ������������ ����
   *   �������� � ����� g_pension_hash, ���� � ��� ��� ������ - �������� ��������� get_pension
   * ��� ������ ������������� - ��������� ��� (purge_pension_hash)
   */
  function get_pay_days(
    p_fk_pension_agreement number, 
    p_month_date           date
  ) return number deterministic
  parallel_enable;
    
  /**
   * ������� get_assignments_cur ���������� �������� ������ 
   *   ��� ���������� �� ��������� ������� � ������
   *
   * @param p_pay_order_id  - 
   * @param p_type_cur      - ��� �������: GC_CURTYP_SIMPLE / GC_CURTYP_COMPOUND / GC_CURTYP_ALL (def)
   * @param p_parallel      - ������� ������������
   * @param p_contract_type - ��� �������������� ����������: GC_CT_ALL(def) / GC_CT_PERIOD / GC_CT_LIFE
   *
   */
  function get_assignments_cur(
    p_pay_order_id     pay_orders.fk_document%type,
    p_type_cur         varchar2 default null,
    p_contract_type    varchar2 default null,
    p_parallel         number   default 4
  ) return sys_refcursor;
  
  /**
   * ����������� ������� ��� ������������� ������ ������� p_cursor 
   */
  function get_assignments_calc(
    p_cursor       sys_refcursor,
    p_fk_pay_order number
  ) return assignments_tbl_typ
    pipelined
    parallel_enable(partition p_cursor by any);
  
  /**
   * ������� fill_charges_by_payorder - ���������� ������ �� ��������� ���������� ������
   */
  procedure calc_assignments(
    p_pay_order_id number,
    p_oper_id      number,
    p_parallel     number default 4
  );
  
  /**
   * ������� ���������� ���������� ���������� ������ �� ��������� pPayOrder
   */
  procedure purge_assignments(
    p_pay_order_id number,
    p_oper_id      number,
    p_commit       boolean default true
  );
  
  /**
   *
   */
  procedure update_pa_periods(
    p_update_date   date,
    p_append_new    boolean default true
  );
  
  /**
   * ��������� ��������� ������� �� ��� � ������� accounts_balance
   * 
   * p_update_date - ����, �� ������� �������������� ������� (��������� �������� ��� ������������)
   *
   */
  procedure update_balances(
    p_update_date date default sysdate
  );
  
end pay_gfnpo_pkg;
/
