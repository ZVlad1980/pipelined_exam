create or replace package import_assignments_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 18.07.2018 10:01:40
  -- Purpose : Импорт начислений по пенсионным соглашениям НПО + связанные сущности (пенс.соглашения и ЛСПВ) из FND
  
  /**
   * Процедура импорта пенс.соглашений, по которым были начисления в заданном периоде (мин. квант - месяц)
   */
  procedure import_pension_agreements(
    p_from_date date,
    p_to_date   date
  );

end import_assignments_pkg;
/
