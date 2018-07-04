/*
select pa.*,
       co.fk_scheme,
       co.fk_account,
       co.fk_contragent
from   contracts          co,
       pension_agreements pa
where  1=1
and    co.fk_company = opscompany
and    co.fk_scheme = opsscheme
and    co.fk_cntr_type = dogtypeagrt
and    co.fk_document = pa.fk_contract
--
and    pa.effective_date <= glastdayofmonth -- дата начала выплат не позже заданного периода выплаты
and    period_code = 1 -- ежемесячно  (для ОПС только =1)
and    expiration_date is null -- пожизненно
and    pa.state = gpastatepay -- фаза выплат
and    pa.isarhv = 0)
*/
select cp.short_name, 
       c.fk_company,
       c.fk_scheme,
       pa.period_code,
       --(select count(1) from pension_agreement_addendums paa where paa.fk_pension_agreement = pa.fk_contract group by 1) cnt_addend,
       --round(avg(pa.amount), 2) avg_amount,
       count(1) cnt
from   contracts c,
       pension_agreements pa,       
       companies cp
where  1=1
and    pa.expiration_date is null
--and    pa.period_code = 1
and    pa.isarhv = 0
and    pa.state = 1
and    pa.fk_contract = c.fk_document
and    cp.fk_contragent = c.fk_company
and    c.fk_cntr_type = 6
and    c.fk_scheme not in (7, 9, 10)
group by cp.short_name, 
       c.fk_company,
       c.fk_scheme,
       pa.period_code
order by cp.short_name, c.fk_scheme
--having count(1) < 100
/
