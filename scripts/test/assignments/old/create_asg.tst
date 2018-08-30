PL/SQL Developer Test script 3.0
23
-- Created on 02.07.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
  l_result number;
  l_time   number;
  /*
  23513113 - 09.06.2018
  23512394 - 25.06.2018
  */
begin
  --dbms_session.reset_package; return;
  -- Test statements here
  l_time   := dbms_utility.get_time;
  l_result := pay_gfnpo_pkg.fill_charges_by_pay_order(
    p_pay_order_id => 23513113,
    p_oper_id      => -1
  );
  dbms_output.put_line('Duration: ' || to_char((dbms_utility.get_time - l_time) / 100) || ' sec');
  if l_result <> 0 then
    raise program_error;
  end if;
  commit;
end;
1
p_pay_order_id
0
-5
2
p_fk_contract
p_amount
