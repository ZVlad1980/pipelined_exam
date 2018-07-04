CREATE OR REPLACE PACKAGE LOG_PKG AS
  /******************************************************************************
   NAME:       LOG_PKG
   PURPOSE:  ������ ������� ������� ���������� ��������
  
           ������� LOGS ����� ��������� ������ ���������� ��������.
           ������ ������ ���������� �� ���������� ����� (����� �����, ���� fk_LOG_MARK). ����� ��������� � ������� LOG_MARKS.
           ������� ������� ������������� ������� �������������� (����� �����, ���� ffk_LOG_WRN_LEVEL). ������� ����������� � ������� LOG_WRN_LEVELS.

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        06.08.2014      Anikin       Created this package.
   1.1        13.10.2017      Zhuravov     ������� ��������� ������� ���������
  ******************************************************************************/

  C_LVL_INF constant number := 1;
  C_LVL_WRN constant number := 2;
  C_LVL_ERR constant number := 3;

  
  -- ������� ������� ������ �� �������� �����
  procedure ClearByMark ( pLogMark in number );
  
  -- ������� ������� ������ �� �������� ����� ������ ����� 
  procedure ClearByToken ( pLogToken in number );  
  
  -- ��������� ��������� � ������  
  procedure WriteAtMark( pLogMark in number, pLogToken in number, pWrnLevel in number, pMsgInfo in varchar2 );


END LOG_PKG;
/
