CREATE OR REPLACE PACKAGE BODY LOG_PKG as

-- очистка журнала, заданного маркой (автономная транзакция)
procedure ClearByMark ( pLogMark in number ) as
 PRAGMA AUTONOMOUS_TRANSACTION;
begin
    Delete from LOGS where fk_LOG_MARK=pLogMark;
    commit;
exception 
    when OTHERS then 
        Rollback;
        Raise;    
end ClearByMark;

-- оудаление группы строк журнала, заданной биркой (автономная транзакция)
procedure ClearByToken ( pLogToken in number ) as
 PRAGMA AUTONOMOUS_TRANSACTION;
begin
    Delete from LOGS where fk_LOG_TOKEN=pLogToken;
    commit;
exception 
    when OTHERS then 
        Rollback;
        Raise;     
end ClearByToken;

-- занесение сообщения  (автономная транзакция)
procedure WriteAtMark( pLogMark in number, pLogToken in number, pWrnLevel in number, pMsgInfo in varchar2 ) as
 PRAGMA AUTONOMOUS_TRANSACTION;
begin   
    Insert into LOGS( fk_LOG_MARK, fk_LOG_TOKEN, fk_LOG_WRN_LEVEL, INFO )  values ( pLogMark, pLogToken , pWrnLevel, pMsgInfo );
    commit;
exception 
    when OTHERS then 
        Rollback;
        Raise;     
end WriteAtMark;

END LOG_PKG;
/
