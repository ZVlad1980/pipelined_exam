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
  function get_assignments_calc(
    p_cursor in sys_refcursor
  ) return assignments_tbl_typ
    pipelined
    parallel_enable(partition p_cursor by any);
  
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
