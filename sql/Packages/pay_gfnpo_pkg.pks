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
   * ������� fill_charges_by_payorder - ���������� ������ �� ��������� ���������� ������
   */
  function fill_charges_by_pay_order(
    p_pay_order_id number,
    p_oper_id      number,
    p_parallel     number default 4
  ) return number;
  
  procedure fill_charges_by_agr_range(
    p_start_id number,
    p_end_id   number
  );

end pay_gfnpo_pkg;
/
