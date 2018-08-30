create or replace package body log_pkg as
  
  GC_OUTPUT_BUFF_SIZE    constant number := 100000;
  
  g_output               boolean := false;
  
  type g_message_typ is record (
    unit_name         varchar2(150),
    unit_line         number,
    message           varchar2(4000),
    user_message      varchar2(4000),
    error_details     varchar2(32767)
  );
  type g_stack_typ is table of g_message_typ;
  
  g_stack_err g_stack_typ;
  
  -- очистка журнала, заданного маркой (автономная транзакция)
  procedure clearbymark(plogmark in number) as
    pragma autonomous_transaction;
  begin
    delete from logs
    where  fk_log_mark = plogmark;
    commit;
  exception
    when others then
      rollback;
      raise;
  end clearbymark;

  -- оудаление группы строк журнала, заданной биркой (автономная транзакция)
  procedure clearbytoken(plogtoken in number) as
    pragma autonomous_transaction;
  begin
    delete from logs
    where  fk_log_token = plogtoken;
    commit;
  exception
    when others then
      rollback;
      raise;
  end clearbytoken;

  -- занесение сообщения  (автономная транзакция)
  procedure writeatmark
  (
    plogmark  in number,
    plogtoken in number,
    pwrnlevel in number,
    pmsginfo  in varchar2
  ) as
    pragma autonomous_transaction;
  begin
    insert into logs
      (fk_log_mark,
       fk_log_token,
       fk_log_wrn_level,
       info)
    values
      (plogmark,
       plogtoken,
       pwrnlevel,
       pmsginfo);
    commit;
  exception
    when others then
      rollback;
      raise;
  end writeatmark;

  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -- API вывода сообщений
  -----------------------------------------------------------------------------------------------

  procedure enable_output(
    p_buffer_size number default null
  ) is 
  begin 
    g_output         := true;
    dbms_output.enable(buffer_size => nvl(p_buffer_size, GC_OUTPUT_BUFF_SIZE)); 
  end enable_output;
  procedure disable_output is begin g_output := false; dbms_output.disable; end;
  
  procedure put(
    p_message varchar2,
    p_eof     boolean default true
  ) is
  begin
    if g_output then
      begin
        if p_eof then
          dbms_output.put_line(p_message);
        else
          dbms_output.put(p_message);
        end if;
      exception
        when others then
          null; --гасим ошибки вывода - не повод стопить программу!
      end;
    end if;
  end put;
  
  procedure put(
    p_message clob
  ) is
  begin
    if g_output then
      begin
        dbms_output.put_line(p_message);
      exception
        when others then
          null; --гасим ошибки вывода - не повод стопить программу!
      end;
    end if;
  end put;
  
  -----------------------------------------------------------------------------------------------
  -- API обработки ошибок
  -----------------------------------------------------------------------------------------------
  
  
  procedure init_exception is
  begin
    g_stack_err := g_stack_typ();
  end init_exception;

  procedure fix_exception(
    p_message      varchar2,
    p_unit_name    varchar2 default null,
    p_unit_line    number   default null,
    p_user_msg     varchar2 default null
  ) is
    l_idx int;
  begin
    if g_stack_err is null then
      init_exception;
    end if;
    
    g_stack_err.extend(1);
    l_idx := g_stack_err.last;
    
    g_stack_err(l_idx).unit_name     := p_unit_name;
    g_stack_err(l_idx).unit_line     := p_unit_line;
    g_stack_err(l_idx).message       := p_message;
    g_stack_err(l_idx).user_message  := p_user_msg;
    g_stack_err(l_idx).error_details := 
      'Error stack: ' || chr(10) || dbms_utility.format_error_stack || chr(10) ||
      'Error backtrace: ' || chr(10) || dbms_utility.format_error_backtrace || chr(10) ||
      'Call stack: ' || chr(10) || dbms_utility.format_call_stack
    ;
    
  end fix_exception;

  procedure show_errors_all is
  begin
    for i in 1..g_stack_err.count loop
      put('Unit_name: ' || g_stack_err(i).unit_name || ' (' || g_stack_err(i).unit_line || ')');
      put('Message: ' || g_stack_err(i).message);
      put('User message: ' || g_stack_err(i).user_message);
      put('Error details:');
      put(g_stack_err(i).error_details);
    end loop;
  end show_errors_all;

  function get_error_msg return varchar2 is
  begin
    return case 
      when g_stack_err is not null and g_stack_err.exists(1) then 
          nvl(g_stack_err(1).user_message, g_stack_err(1).message) 
    end;
  end get_error_msg;

end log_pkg;
/
