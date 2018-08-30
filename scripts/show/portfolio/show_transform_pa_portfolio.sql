/*select tpa.ssylka_fl,
       tpa.date_nach_vypl
from   transform_pa    tpa
where  tpa.fk_contract is not null
minus--*/
select tpp.ssylka_fl,
       tpp.date_nach_vypl,
       fl.familiya || ' ' || fl.imya || ' ' || fl.otchestvo || ' (' || to_char(fl.data_rogd, 'dd.mm.yyyy') || ')' fio,
       rdi.num_from,
       rdi.dept_from,
       rdi.folder_from,
       tpp.source_table,
       tpp.pd_creation_date,
       tpp.change_date,
       tpp.kod_izm,
       tpp.kod_doc,
       tpp.nom_izm,
       tpp.true_kod_izm,
       tpp.fk_pay_portfolio --*/
from   transform_pa_portfolio tpp,
       fnd.reg_doc_insz       rdi,
       fnd.sp_fiz_lits        fl
where 1=1
and   rdi.kod_insz = tpp.kod_doc
and   fl.ssylka = tpp.ssylka_fl
/
--отсутствующие
select tpa.*
from   transform_pa            tpa,
       transform_pa_portfolios tpp
where  1=1
and    tpp.fk_pay_portfolio is null
and    tpp.date_nach_vypl(+) = tpa.date_nach_vypl
and    tpp.ssylka_fl(+) = tpa.ssylka_fl
and    tpa.fk_contract is not null
