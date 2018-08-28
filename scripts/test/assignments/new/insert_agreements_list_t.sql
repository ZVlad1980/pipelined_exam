declare
  c_pay_date constant date := to_date(20180710, 'yyyymmdd');
begin
  execute immediate 'truncate table agreements_list_t';
  insert into agreements_list_t(
    id,
    fk_contract,
    period_code,
    fk_debit,
    fk_credit,
    fk_scheme,
    fk_contragent,
    effective_date,
    last_pay_date,
    creation_date
  ) select /*+ parallel(4)*/
           rownum,
           fk_contract,
           period_code,
           fk_debit,
           fk_credit,
           fk_scheme,
           fk_contragent,
           effective_date,
           least(last_pay_date, c_pay_date) last_pay_date, --окнечная дата зависит от period_code
           creation_date
    from   pension_agreements_charge_v pa
    where  pa.effective_date <= c_pay_date;
  commit;
  dbms_stats.gather_table_stats(user, upper('agreements_list_t'), cascade => true);
end;
/
select /*+ parallel(4)*/
           rownum,
           fk_contract,
           period_code,
           fk_debit,
           fk_credit,
           fk_scheme,
           fk_contragent,
           effective_date,
           least(last_pay_date, c_pay_date) last_pay_date, --îêíå÷íàÿ äàòà çàâèñèò îò period_code
           creation_date
    from   pension_agreements_charge_v pa
    where  pa.effective_date <= c_pay_date;
