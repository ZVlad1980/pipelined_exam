select pd.ssylka,
       pa.*,
       pd.*
from   pension_agreements    pa,
       transform_contragents tc,
       fnd.Sp_Pen_Dog_Imp_v  pd
where  1=1
and    pd.data_nach_vypl = pa.effective_date
and    pd.ssylka = tc.ssylka_fl
and    tc.fk_contract = pa.fk_base_contract
and    pa.fk_contract = &contract --3652403
/
select *
from   fnd.vypl_pen vp
where  vp.ssylka_fl = &ssylka
order by vp.data_nachisl desc
/
select *
from   fnd.sp_ogr_pv_imp_v op
where  op.ssylka_fl = &ssylka
/
select *
from    fnd.sp_pen_dog_imp_v pd
where   pd.ssylka = &ssylka
/
select *
from   pay_restrictions pr
where  pr.fk_doc_with_acct = &contract
/
	select pa.fk_contract
  from   fnd.vypl_pen_imp_v    vp,
         transform_contragents tc,
         pension_agreements_v  pa
  where  1=1
  and    pa.effective_date = vp.data_nach_vypl
  and    pa.fk_base_contract = tc.fk_contract
  and    tc.ssylka_fl = vp.ssylka_fl
  and    vp.data_op = to_date('10.07.2018', 'dd.mm.yyyy')
  and    vp.ssylka_fl = &ssylka
