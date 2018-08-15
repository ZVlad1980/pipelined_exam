create or replace package assignments_api is

  -- Author  : V.ZHURAVOV
  -- Created : 30.06.2018 15:22:08
  -- Purpose : 
  
  procedure init(
    p_err_tag varchar2 default null
  );
  
  procedure flush;
  
  procedure push(p_assignment assignments%rowtype);

end assignments_api;
/
