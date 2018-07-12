--2762766
select *--a.fk_doc_with_acct, round(a.amount, 2) amount
from   assignments a
where  1=1
and    a.fk_doc_with_acct = 2762924
and    a.fk_doc_with_action = 23236674
/
select *
from   pension_agreement_addendums pa
where  pa.fk_pension_agreement = 2762924
/
select 
/
select vp.*--doc.ref_kodinsz, round(vp.summa, 2) amount
from   fnd.vypl_pen   vp,
       fnd.sp_pen_dog doc
where  vp.nom_vkl = doc.nom_vkl
and    vp.nom_ips = doc.nom_ips
--and    vp.tip_vypl in (1, 3, 6, 91)
and    vp.data_nachisl < to_date(20180601, 'yyyymmdd')
and    doc.ref_kodinsz = 2762924
/
select *
from   fnd.sp_pen_dog doc
where  doc.ref_kodinsz = 2762924
/
select p.*--dop_pen
from   fnd.sp_fiz_lits p
where  p.ssylka = 11820 --9039,2 9065.04
/
select *
from   fnd.RZTB_ISTOR_OBYAZ	 io
where  io.ssylka = 297206
/
select *
from   fnd.sp_pen_dog doc
where  doc.ref_kodinsz = 2767448
/
select pa.*
from   contracts c,
       pension_agreements pa,
       pension_agreement_addendums paa
where  c.fk_contragent = 2905022
and    c.fk_cntr_type = 6
and    pa.fk_contract = c.fk_document
and    paa.fk_pension_agreement(+) = pa.fk_contract
