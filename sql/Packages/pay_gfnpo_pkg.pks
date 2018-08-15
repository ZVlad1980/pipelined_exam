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
  function fill_charges_by_pay_order(
    p_pay_order_id number,
    p_oper_id      number,
    p_parallel     number default 4
  ) return number;

end pay_gfnpo_pkg;
/
