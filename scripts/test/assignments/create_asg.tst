PL/SQL Developer Test script 3.0
17
-- Created on 02.07.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
  l_result number;
begin
  --dbms_session.reset_package; return;
  -- Test statements here
  l_result := pay_gfnpo_pkg.fill_charges_by_pay_order(
    p_pay_order_id => 23159079,
    p_oper_id      => -1
  );
  
  if l_result <> 0 then
    raise program_error;
  end if;
  commit;
end;
0
2
p_fk_contract
p_amount
