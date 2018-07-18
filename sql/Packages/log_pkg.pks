CREATE OR REPLACE PACKAGE LOG_PKG AS
  /******************************************************************************
   NAME:       LOG_PKG
   PURPOSE:  запись журнала событий выполнени€ процедур
  
           “аблица LOGS может содержать записи нескольких журналов.
            аждый журнал отличаетс€ по уникальной ћј– ≈ (целое число, поле fk_LOG_MARK). ћарки занос€тс€ в таблицу LOG_MARKS.
           «апис€м журнала присваиваетс€ уровень предупреждени€ (целое число, поле ffk_LOG_WRN_LEVEL). ”ровени перечислены в таблице LOG_WRN_LEVELS.

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        06.08.2014      Anikin       Created this package.
   1.1        13.10.2017      Zhuravov     ƒобавил константы уровней сообщений
   1.2        18.07.2018      Zhuravov     ƒобавил API обработки ошибок и вывода сообщений
  ******************************************************************************/

  C_LVL_INF constant number := 1;
  C_LVL_WRN constant number := 2;
  C_LVL_ERR constant number := 3;

  
  -- очистка журнала ошибок по заданной марке
  procedure ClearByMark ( pLogMark in number );
  
  -- очистка журнала ошибок по заданной бирке группы строк 
  procedure ClearByToken ( pLogToken in number );  
  
  -- занесение сообщени€ в журнал  
  procedure WriteAtMark( pLogMark in number, pLogToken in number, pWrnLevel in number, pMsgInfo in varchar2 );
  
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -- API вывода сообщений
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
  -- API обработки ошибок
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
