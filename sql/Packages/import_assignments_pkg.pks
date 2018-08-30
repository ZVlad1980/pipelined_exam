create or replace package import_assignments_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 18.07.2018 10:01:40
  -- Purpose : ������ ���������� �� ���������� ����������� ��� + ��������� �������� (����.���������� � ����) �� FND

  /**
  * ��������� ������� ����.����������, �� ������� ���� ���������� � �������� ������� (���. ����� - �����)
  *  ������� ������:
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
  *  �������� ������:
  *    select * from ERR$_IMP_DOCUMENTS where ORA_ERR_TAG$ = &l_err_tag;
  *    select * from ERR$_IMP_CONTRACTS where ORA_ERR_TAG$ = &l_err_tag;
  *    select * from ERR$_IMP_PENSION_AGREEMENTS where ORA_ERR_TAG$ = &l_err_tag;
  *  l_err_tag - ��������� � output
  */
  procedure import_pension_agreements
  (
    p_from_date date,
    p_to_date   date,
    p_commit    boolean default true
  );
  
  /**
   * ��������� �������� ������������� ������ � ��������� GAZFOND � �������������� � FND
   */
  procedure update_period_code(
    p_commit boolean default true
  );
  
  /**
  * ��������� ������� ��������� � ����.�����������
  *  ������� ������:
  *    begin
  *      log_pkg.enable_output;
  *      import_assignments_pkg.import_pa_addendums;
  *    exception
  *      when others then
  *        log_pkg.show_errors_all;
  *        raise;
  *    end;
  *
  *  l_err_tag - ��������� � output
  */
  procedure import_pa_addendums(
    p_commit    boolean default true
  );

  /**
  * ��������� ������� ����������� ������
  *  ������� ������:
  *    begin
  *      log_pkg.enable_output;
  *      import_assignments_pkg.import_pay_restrictions;
  *    exception
  *      when others then
  *        log_pkg.show_errors_all;
  *        raise;
  *    end;
  *
  *  l_err_tag - ��������� � output
  */
  procedure import_pay_restrictions(
    p_commit    boolean default true
  );

  /**
  * ��������� �������� ����
  *   �������������� ������������ ������ �� ���� ������
  *
  *  ������� ������:
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
  *  �������� �� ��������������� ����������:
  *    select * from transform_pa_accounts tpa where nvl(tpa.fk_account, 0) > 0
  *  �������� ������ �������:
  *  l_err_tag - ��������� � output
  */
  procedure create_accounts
  (
    p_from_date date,
    p_to_date   date,
    p_commit    boolean default true
  );

  /**
  * ��������� ������� ������ import_assignments
  *   �������������� ������������ ������ �� ���� ������,
  *    ��� ��������� ������� ����� ��������������� ����������
  *    �� ����������� ������� ���������� (���� ���)
  *
  * p_from_date - ���� ������� ���������� (�����)
  * p_to_date   - ���� ���������� ���������� (�����)
  * p_commit    - boolean, def: TRUE
  * 
  *  ������� ������:
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
  *  �������� ������ �������:
  *    select * from ERR$_IMP_PAY_ORDERS ea where ea.ORA_ERR_TAG$ = &l_err_tag;
  *    select * from ERR$_IMP_ASSIGNMENTS ea where ea.ORA_ERR_TAG$ = &l_err_tag;
  *    
  *  l_err_tag - ��������� � output
  */
  procedure import_assignments
  (
    p_from_date date,
    p_to_date   date
  );
  
  function get_sspv_id(
    p_fk_scheme accounts.fk_scheme%type
  ) return accounts.id%type
  result_cache;

end import_assignments_pkg;
/
