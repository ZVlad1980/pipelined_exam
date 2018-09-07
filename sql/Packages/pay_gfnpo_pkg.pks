create or replace package pay_gfnpo_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 29.06.2018 11:08:41
  -- Purpose : 


  /**
   */
  function add_month$(
    p_date   date,
    p_months int
  ) return date;
  
  /**
   * Функция fill_charges_by_payorder - начисление пенсий по заданному платежному ордеру
   */
  procedure calc_assignments(
    p_pay_order_id number,
    p_oper_id      number,
    p_parallel     number default 4
  );
  
  /**
   * Функция откатывает результаты начислений пенсий по заданному pPayOrder
   */
  procedure purge_assignments(
    p_pay_order_id number,
    p_oper_id      number,
    p_commit       boolean default true
  );

  function get_assignments_calc(
    p_cursor in sys_refcursor
  ) return assignments_tbl_typ
    pipelined
    parallel_enable(partition p_cursor by any);
  
  procedure update_pa_periods(
    p_update_date   date,
    p_append_new    boolean default true
  );

  /**
   * WRAP функция для процедуры calc_assignments (единообразие - поддержка сущ.API (см. PAY_GFOPS_PKG)
   * заполнить таблицу начислений пенсий
   */
  -- 
  function Fill_Charges_by_PayOrder( pPayOrder in number, pOperID in number ) RETURN NUMBER;
  
  /**
   * WRAP функция для purge_assignments - поддержка сущ.API (см. PAY_GFOPS_PKG)
   * очистка таблиц для отката операций по заданному распоряжению
   * удалить начисления
   */
  function Wipe_Charges_by_PayOrder( pPayOrder in number, pOperID in number, pDoNotCommit in number default 0 ) RETURN NUMBER;
  
end pay_gfnpo_pkg;
/
