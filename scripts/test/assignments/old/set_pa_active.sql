/*
--Копия состояния
alter table pension_agreements add state_copy number(5) 
/
--сброс активности, с копированием состояния
update pension_agreements 
set    state_copy = state,
       state = 2
/
--установка активности целевым соглашениям, по которым были начисления в заданном периоде
update pension_agreements pa
set    pa.state = 1 --pa.state + 100
where  pa.state <> 1
and    pa.fk_contract in (
         select vp.ref_kodinsz
         from   fnd.vypl_pen_imp_v   vp
         where  1=1
         and    vp.data_op = to_date('09.06.2018', 'dd.mm.yyyy') -- to_date('25.06.2018', 'dd.mm.yyyy'))
       )
/
*/
--Проверка активности соглашений по начислениям за период
select vp.ref_kodinsz, vp.*
from   fnd.vypl_pen_imp_v   vp,
       pension_agreements_v pa
where  1=1
and    pa.fk_base_contract is null
and    pa.state(+) = 1
and    pa.fk_contract(+) = vp.ref_kodinsz
and    vp.data_op in (to_date('09.06.2018', 'dd.mm.yyyy'))--, to_date('25.06.2018', 'dd.mm.yyyy'))
/
--Обратная проверка 
select pa.*
from   fnd.vypl_pen_imp_v   vp,
       pension_agreements_v pa
where  1=1
and    vp.ssylka_fl is null
and    vp.ref_kodinsz(+) = pa.fk_contract
and    vp.data_op(+) in (to_date('09.06.2018', 'dd.mm.yyyy'))--, to_date('25.06.2018', 'dd.mm.yyyy'))
and    pa.state = 1
/
