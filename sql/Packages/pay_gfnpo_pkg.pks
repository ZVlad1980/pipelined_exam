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
  function calc_assignments(
    p_pay_order_id number,
    p_oper_id      number,
    p_parallel     number default 4
  ) return number;
  
  /**
   * Функция откатывает результаты начислений пенсий по заданному pPayOrder
   */
  function purge_assignments(
    p_pay_order_id number,
    p_oper_id      number,
    p_commit       number default 0
  ) return number;

  function get_assignments_calc(
    p_cursor in sys_refcursor
  ) return assignments_tbl_typ
    pipelined
    parallel_enable(partition p_cursor by any);
  
  procedure update_pa_periods(
    p_update_date   date,
    p_append_new    boolean default true
  );
  
end pay_gfnpo_pkg;
/
