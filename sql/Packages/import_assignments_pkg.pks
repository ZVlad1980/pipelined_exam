create or replace package import_assignments_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 18.07.2018 10:01:40
  -- Purpose : Импорт начислений по пенсионным соглашениям НПО + связанные сущности (пенс.соглашения и ЛСПВ) из FND
  
  /**
   * Процедура импорта пенс.соглашений, по которым были начисления в заданном периоде (мин. квант - месяц)
   *  Разовый запуск:
   *    begin
   *      log_pkg.enable_output;
   *      import_assignments_pkg.import_pension_agreements(
   *        p_from_date => to_date(19800101, 'yyyymmdd'),
   *        p_to_date   => sysdate
   *      );
   *    exception
   *      when others then
   *        log_pkg.show_errors_all;
   *        raise;
   *    end;
   *
   *  Просмотр ошибок:
   *    select * from ERR$_IMP_DOCUMENTS where ORA_ERR_TAG$ = &l_err_tag;
   *    select * from ERR$_IMP_CONTRACTS where ORA_ERR_TAG$ = &l_err_tag;
   *    select * from ERR$_IMP_PENSION_AGREEMENTS where ORA_ERR_TAG$ = &l_err_tag;
   *  l_err_tag - выводится в output
   */
  procedure import_pension_agreements(
    p_from_date date,
    p_to_date   date,
    p_commit    boolean default true
  );
  
  /**
   * Процедура создания ЛСПВ
   *   Поддерживается многоразовый запуск за один период
   *
   *  Разовый запуск:
   *    begin
   *      log_pkg.enable_output;
   *      import_assignments_pkg.create_accounts(
   *        p_from_date => to_date(19800101, 'yyyymmdd'),
   *        p_to_date   => sysdate
   *      );
   *    exception
   *      when others then
   *        log_pkg.show_errors_all;
   *        raise;
   *    end;
   *
   *  Просмотр не импортированных соглашений:
   *    select * from transform_pa_accounts tpa where nvl(tpa.fk_account, 0) > 0
   *  Просмотр ошибок импорта:
   *  l_err_tag - выводится в output
   */
  procedure create_accounts(
    p_from_date date,
    p_to_date   date,
    p_commit    boolean default true
  );
  
  /**
   * Процедура импорта выплат import_assignments
   *   Поддерживается многоразовый запуск за один период,
   *    при повторном запуске будут импортироваться начисления
   *    за пропущенные периоды начислений (пока так)
   *
   * p_from_date - дата первого начисления (месяц)
   * p_to_date   - дата последнего начисления (месяц)
   * p_commit    - boolean, def: TRUE
   * 
   *  Разовый запуск:
   *    begin
   *      log_pkg.enable_output;
   *      import_assignments_pkg.import_assignments(
   *        p_from_date => to_date(19960101, 'yyyymmdd'),
   *        p_to_date   => to_date(19961231, 'yyyymmdd')
   *      );
   *    exception
   *      when others then
   *        log_pkg.show_errors_all;
   *        raise;
   *    end;
   *
   *  Просмотр ошибок импорта:
   *    select * from ERR$_IMP_PAY_ORDERS ea where ea.ORA_ERR_TAG$ = &l_err_tag;
   *    select * from ERR$_IMP_ASSIGNMENTS ea where ea.ORA_ERR_TAG$ = &l_err_tag;
   *    
   *  l_err_tag - выводится в output
   */
  procedure import_assignments(
    p_from_date date,
    p_to_date   date
  );

end import_assignments_pkg;
/
