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
   1.2        18.07.2018      Zhuravov     ������� API ��������� ������ � ������ ���������
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
  
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -- API ������ ���������
  -----------------------------------------------------------------------------------------------
  procedure enable_output(
    p_buffer_size number default null
  );
  procedure disable_output;
  
  procedure put(
    p_message varchar2,
    p_eof     boolean default true
  );
  
  -----------------------------------------------------------------------------------------------
  -- API ��������� ������
  -----------------------------------------------------------------------------------------------
  
  procedure init_exception;
  
  procedure fix_exception(
    p_message      varchar2,
    p_unit_name    varchar2 default null,
    p_unit_line    number   default null,
    p_user_msg     varchar2 default null
  );
  
  procedure show_errors_all;
  
  function get_error_msg return varchar2;
  
END LOG_PKG;
/
