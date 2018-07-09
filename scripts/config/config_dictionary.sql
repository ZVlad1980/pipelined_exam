--Создание ССПВ для 1, 5, 6 схем
declare
  GC_ACCT_TYPE_SSPV constant int := 4;
  GC_ACT_CRACCT     constant int := 50;
  
  l_account_fk accounts.id%type;
  
  l_schemes sys.odcinumberlist := 
    sys.odcinumberlist(1, 5, 6);
    
  function create_account(
    p_scheme int
  ) return int is
    l_action_fk actions.id%type;
    l_result int;
  begin
    insert into actions(
      action_date,
      fk_action_type,
      fk_operator,
      creation_date,
      fk_creator
    ) values (
      sysdate,
      GC_ACT_CRACCT,
      0,
      sysdate,
      0
    ) return id into l_action_fk;
    --
    insert into accounts(
      acct_number,
      title,
      fk_acct_type,
      fk_scheme,
      fk_opened
    ) values (
      9990 - p_scheme,
      'ССПВ сх ' || to_char(p_scheme),
      GC_ACCT_TYPE_SSPV,
      p_scheme,
      l_action_fk
    ) return id into l_result;
    --
    return l_result;
  end create_account;
  
begin
  --return;
  for i in 1..l_schemes.count loop
    begin
      select id
      into   l_account_fk 
      from   accounts a
      where   a.fk_acct_type = GC_ACCT_TYPE_SSPV
      and     a.fk_scheme = l_schemes(i);
    exception
      when no_data_found then
        l_account_fk := create_account(l_schemes(i));
    end;
    dbms_output.put_line('Scheme ' || l_schemes(i) || ', SSPV id: ' || l_account_fk);
  end loop;
end;
/
