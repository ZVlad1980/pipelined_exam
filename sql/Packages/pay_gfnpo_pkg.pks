create or replace package pay_gfnpo_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 29.06.2018 11:08:41
  -- Purpose : 


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
  
  /**
   * Процедура чистит пакетный кэш 
   */
  procedure purge_hash_pkg;
  
  /**
   * Функция расчета размера пенсии за заданный месяц
   *   Вызывается при начислении пенсии, если в месяце выплат есть дробные ограничения или дробное заверешние выплат
   * При первом использовании - почистить кеш (purge_pension_hash)
   */
  function get_pension(
    p_fk_pension_agreement number, 
    p_month_date           date
  ) return number deterministic
  parallel_enable;
  
  /**
   * Функция возвращает количество оплачиваемых дней
   *   Работает с кэшем g_pension_hash, если в нем нет данных - вызывает процедуру get_pension
   * При первом использовании - почистить кеш (purge_pension_hash)
   */
  function get_pay_days(
    p_fk_pension_agreement number, 
    p_month_date           date
  ) return number deterministic
  parallel_enable;
    
  /**
   * Функция get_assignments_cur возвращает открытый курсор 
   *   Для начислений по заданному периоду и ордеру
   *
   * @param p_pay_order_id  - 
   * @param p_type_cur      - тип курсора: GC_CURTYP_SIMPLE / GC_CURTYP_COMPOUND / GC_CURTYP_ALL (def)
   * @param p_parallel      - степень параллелизма
   * @param p_contract_type - тип обрабатываемых контрактов: GC_CT_ALL(def) / GC_CT_PERIOD / GC_CT_LIFE
   *
   */
  function get_assignments_cur(
    p_pay_order_id     pay_orders.fk_document%type,
    p_type_cur         varchar2 default null,
    p_contract_type    varchar2 default null,
    p_parallel         number   default 4
  ) return sys_refcursor;
  
  /**
   * внутреннее использование
   */
  function get_assignments_calc(
    p_cursor in sys_refcursor
  ) return assignments_tbl_typ
    pipelined
    parallel_enable(partition p_cursor by any);
  
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
  
  /**
   *
   */
  procedure update_pa_periods(
    p_update_date   date,
    p_append_new    boolean default true
  );
  
  /**
   * Процедура обновляет остатки по ИПС в таблице accounts_balance
   * 
   * p_update_date - дата, на которую рассчитываются остатки (временный параметр для тестирования)
   *
   */
  procedure update_balances(
    p_update_date date default sysdate
  );
  
end pay_gfnpo_pkg;
/
