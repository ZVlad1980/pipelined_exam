/*
with w_months as ( --список обрабатываемых месяцев
  select /*+ materialize
         m.month_date,
         last_day(m.month_date) end_month_date
  from   lateral(
              select add_months(trunc(to_date(20180630, 'yyyymmdd'), 'MM'), -1 * (level - 1)) month_date
              from   dual
              connect by level < 361
         ) m
)*/
/**/
merge into pension_agreement_periods pap
using (select pac.fk_contract,
              trunc(pac.effective_date, 'MM') effective_date
       from   pension_agreements_charge_v pac
      ) u
on    (pap.fk_pension_agreement = u.fk_contract)
when not matched then
  insert(fk_pension_agreement, last_assign_date )
  values(u.fk_contract, u.effective_date)
/
commit
/
merge into pension_agreement_periods pap
using (
        with w_months as ( --список обрабатываемых месяцев
          select /*+ materialize*/
                 m.month_date,
                 last_day(m.month_date) end_month_date
          from   lateral(
                      select add_months(trunc(to_date(20180630, 'yyyymmdd'), 'MM'), -1 * (level - 1)) month_date
                      from   dual
                      connect by level < 361
                 ) m
        )
        select /*+ parallel(5)*/pap.fk_pension_agreement,
               add_months(min(m.month_date), -1) last_assign_date
        from   pension_agreement_periods pap,
               w_months                  m
        where  1=1
        and    not exists ( --нет активного ограничения на этот месяц
                 select 1
                 from   pay_restrictions pr
                 where  pr.effective_date between m.month_date and m.end_month_date
                 and    pr.fk_document_cancel is null
                 and    pr.fk_doc_with_acct = pap.fk_pension_agreement
               )
        and    not exists(
                 select 1
                 from   assignments               asg
                 where  asg.fk_paycode = 5000
                 and    asg.fk_asgmt_type = 2
                 and    asg.paydate between m.month_date and m.end_month_date
                 and    asg.fk_doc_with_acct = pap.fk_pension_agreement
               )
        and    m.month_date >= pap.last_assign_date
        group by pap.fk_pension_agreement
      ) u
on    (pap.fk_pension_agreement = u.fk_pension_agreement)
when matched then
  update set
    pap.last_assign_date = u.last_assign_date
/
