select pa.fk_contract,
       pa.fk_base_contract,
       bco.fk_account fk_debit,
       co.fk_account fk_credit,
       co.fk_scheme,
       co.fk_contragent,
       pa.effective_date,
       pa.amount,
       last_day(coalesce(p.deathdate, to_date(20180430, 'yyyymmdd'))) + 1 death_month
from   contracts          co,
       pension_agreements pa,
       contracts          bco,
       people             p
where  1 = 1
      --
and    bco.fk_document = pa.fk_base_contract
      --
and    p.fk_contragent = co.fk_contragent
      --
/*and    case
        when p_filter_company = 'NO' or exists
         (select 1
              from   pay_order_filters pof
              where  pof.filter_value = co.fk_company
              and    pof.filter_code = gc_pofltr_company
              and    pof.fk_pay_order = p_pay_order) then
         1
        else
         0
      end = 1*/
and    case
        when /*p_filter_contract = 'NO' or */exists
         (select 1
              from   pay_order_filters pof
              where  pof.filter_value = co.fk_document
              and    pof.filter_code = 'CONTRACT'
              and    pof.fk_pay_order = 23159064) then
         1
        else
         0
      end = 1
      --
and    co.fk_document = pa.fk_contract
and    co.fk_company <> 1001
and    co.fk_scheme <> 7
and    co.fk_cntr_type = 6
      --
and    not exists (select 1
        from   registry_details rd,
               registries       rg,
               registry_types   rt
        where  rt.stop_pays = 1
        and    rt.id = rg.fk_registry_type
        and    rg.id = rd.fk_registry
        and    rd.fk_contract = pa.fk_base_contract)
      --
and    pa.effective_date <= to_date(20180430, 'yyyymmdd') -- дата начала выплат не позже заданного периода выплаты
      --and    pa.period_code = 1 --ни тока лишь все )))
      --and    pa.expiration_date is null -- пожизненно
and    pa.expiration_date is null/*case
        when p_contract_type = gc_cntrct_all then
         1
        when p_contract_type = gc_cntrct_life and
             pa.expiration_date is null then
         1
        when p_contract_type = gc_cntrct_term and
             pa.expiration_date is not null then
         1
        else
         0
      end = 1*/
and    pa.state = 1 -- фаза выплат
and    pa.isarhv = 0
