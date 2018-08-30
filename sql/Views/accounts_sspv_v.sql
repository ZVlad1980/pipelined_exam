create or replace view accounts_sspv_v as
  select a.fk_scheme,
         a.id,
         a.acct_number,
         a.title
  from   accounts a
  where  a.fk_acct_type = 4
/
