CREATE OR REPLACE PACKAGE LOG_PKG AS
  /******************************************************************************
   NAME:       LOG_PKG
   PURPOSE:  запись журнала событий выполнения процедур
  
           Таблица LOGS может содержать записи нескольких журналов.
           Каждый журнал отличается по уникальной МАРКЕ (целое число, поле fk_LOG_MARK). Марки заносятся в таблицу LOG_MARKS.
           Записям журнала присваивается уровень предупреждения (целое число, поле ffk_LOG_WRN_LEVEL). Уровени перечислены в таблице LOG_WRN_LEVELS.

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        06.08.2014      Anikin       Created this package.
   1.1        13.10.2017      Zhuravov     Добавил константы уровней сообщений
  ******************************************************************************/

  C_LVL_INF constant number := 1;
  C_LVL_WRN constant number := 2;
  C_LVL_ERR constant number := 3;

  
  -- очистка журнала ошибок по заданной марке
  procedure ClearByMark ( pLogMark in number );
  
  -- очистка журнала ошибок по заданной бирке группы строк 
  procedure ClearByToken ( pLogToken in number );  
  
  -- занесение сообщения в журнал  
  procedure WriteAtMark( pLogMark in number, pLogToken in number, pWrnLevel in number, pMsgInfo in varchar2 );


END LOG_PKG;
/
