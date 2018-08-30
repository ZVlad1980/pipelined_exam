--truncate table transform_pa_restrictions

select *
from  transform_pa_restrictions tpr,
      pay_restrictions          pr
where tpr.fk_pay_restriction in (
select tpr.fk_pay_restriction
from   transform_pa_restrictions tpr
where  tpr.fk_pay_restriction is not null
group by tpr.fk_pay_restriction
having count(1) > 1
)
and  pr.id = tpr.fk_pay_restriction
order by tpr.fk_pay_restriction, tpr.kod_ogr_pv
/
select *
from   transform_pa_restrictions tpr
where  tpr.fk_contract is not null
and    tpr.fk_pay_restriction is null
