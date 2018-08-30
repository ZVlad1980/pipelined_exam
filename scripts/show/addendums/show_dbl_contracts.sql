/*
--online view
select paa.*
from   (
select pa.*,
       row_number()over(partition by pa.fk_base_contract order by pa.effective_date) rn,
       count(1)over(partition by pa.fk_base_contract) cnt
from   pension_agreements pa,
       contracts          cn
where  cn.fk_document = pa.fk_base_contract
and    cn.fk_scheme in (1,2,3,4,5,6,8)
) pa,
pension_agreements paa
where 1=1
and   paa.fk_base_contract = pa.fk_base_contract
and   pa.rn < pa.cnt
and   pa.isarhv = 0
order by paa.fk_base_contract, paa.effective_date
*/
create table pension_agreements_dbl_t as
select row_number()over(partition by pa.fk_base_contract order by pa.effective_date) rn,
       count(1)over(partition by pa.fk_base_contract) cnt,
       pa.*
from   pension_agreements_v pa
where  pa.fk_base_contract in (
select pa.fk_base_contract
from   (select pa.fk_base_contract,
               pa.isarhv,
               row_number()over(partition by pa.fk_base_contract order by pa.effective_date) rn,
               count(1)over(partition by pa.fk_base_contract) cnt
        from   pension_agreements_v pa
       ) pa
where  pa.rn < pa.cnt
)
/
--активные двойники
select *
from   pension_agreements_dbl_t pa
where  pa.fk_base_contract in (
select pa.fk_base_contract
from   pension_agreements_dbl_t pa
where  pa.rn < pa.cnt
and    pa.isarhv = 0
)
order by pa.fk_base_contract
/
select case when exists(select 1 from pension_agreement_addendums paa where paa.fk_pension_agreement = pa.fk_contract) then 'Y' else 'N' end add_exists,
       pa.*
from   pension_agreements_dbl_t pa
where  pa.fk_base_contract in (
select pa.fk_base_contract
from   pension_agreements_dbl_t pa
where  exists(select 1 from pension_agreement_addendums paa where paa.fk_pension_agreement = pa.fk_contract)
and    pa.rn < pa.cnt
)
order by pa.fk_base_contract, pa.effective_date
/
/*
--off duplicate pa
update pension_agreements pa
set    pa.isarhv = 1,
       pa.state  = 2
where  pa.fk_contract IN (   
11596322,
23357819,
15779745
)
*/
