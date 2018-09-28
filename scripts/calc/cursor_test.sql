/*
begin
dbms_session.reset_package;
end;
/
begin
  log_pkg.enable_output;
end;
fk_pay_order := 23864557
*/
--delete from pay_order_filters where fk_pay_order = &po_id;
declare
  l_po_id number := &po_id;
begin
  log_pkg.enable_output;
  merge into pay_order_filters pof
  using (select l_po_id fk_pay_order, 'CONTRACT' filter_code, 23278864 filter_value from dual
        ) u
  on    (pof.fk_pay_order = u.fk_pay_order and pof.filter_code = u.filter_code and pof.filter_value = u.filter_value)
  when not matched then
    insert(fk_pay_order, filter_code, filter_value)
      values(u.fk_pay_order, u.filter_code, u.filter_value)
  ;
  /*
  delete from pay_order_filters where fk_pay_order = l_po_id;
  */
  commit;
  pay_gfnpo_pkg.purge_hash_pkg;
end;
/
select t.*
from   table(pay_gfnpo_pkg.get_assignments_calc(pay_gfnpo_pkg.get_assignments_cur(&po_id))) t
