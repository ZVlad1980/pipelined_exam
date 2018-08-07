select * from sp_pen_dog_arh spda where spda.ssylka=60130
vkl=140
select * from reg_doc_vu vu where vu.ssylka_fl=60130

101600
194535
373763

select iz.*,
       ik.val
from   izmeneniya  iz,
       izm_key_val ik
where  iz.nom_izm = ik.nom_izm
and    ik.nom_trans = 1
and    ik.fld_nom = 1
and    iz.kod_izm in
       (12, 24, 66, 68, 81, 87, 88, 89, 90, 92, 107, 109, 72, 73)
and    ik.val = '60130'


select * from izm_spr_soderg iss where iss.kod_izm in (12,24,72,73)

select * from reg_doc_insz rdi where rdi.kod_insz in (40519,366603)

select * from gazfond.documents d where d.id in (40519,366603)
-- fk_mse_sertificate
select * from gazfond.pay_portfolios pp where  pp.fk_app_type in (4,5,6)

select * from gazfond.pay_decisions 

select * from cdm.pay_request_types

select * from izm_spr_soderg iss

select IZ.*,ik.val, id.kod_dat, id.old_val, id.new_val 
from izmeneniya iz, izm_key_val ik, izm_data id 
where iz.nom_izm = ik.nom_izm
and ik.nom_trans=1
and ik.fld_nom=1
and iz.kod_izm in (11)
and id.nom_izm = iz.nom_izm
--and id.nom_rec = 1
and ik.val= '60130'

select * from izm_spr_flds isf where isf.kod_izm = 11

select tb.fk_bank_account from gazfond.transform_banks tb where tb.kod_bank in (677, 5480)
  

select * from gazfond.pay_details pd where (pd.fk_bank_account, pd.personal_account) in 
(select 27224, '42306810154121125384/34' from dual)

--324041

С уважением,
Танцур Александр, т. 67-202

