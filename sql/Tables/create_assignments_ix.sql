create index assignments_ix on assignments(fk_asgmt_type, paydate, fk_doc_with_acct, fk_paycode)
/
begin
  --dbms_stats.gather_table_stats(user, 'ASSIGNMENTS', cascade => true);
  dbms_stats.gather_index_stats(user, 'ASSIGNMENTS_IX');
end;
