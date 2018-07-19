create or replace package import_assignments_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 18.07.2018 10:01:40
  -- Purpose : ������ ���������� �� ���������� ����������� ��� + ��������� �������� (����.���������� � ����) �� FND
  
  /**
   * ��������� ������� ����.����������, �� ������� ���� ���������� � �������� ������� (���. ����� - �����)
   */
  procedure import_pension_agreements(
    p_from_date date,
    p_to_date   date
  );

end import_assignments_pkg;
/
