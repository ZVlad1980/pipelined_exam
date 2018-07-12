/*
select --a.*, a.rowid
       count(1)
--delete
from   assignments a
where  1=1
and    a.fk_doc_with_action = 23236674
--and    a.fk_doc_with_acct = 13464073
order by a.paydate
/
--delete from err$_assignments
select *
from   err$_assignments
/
select count(1)
from   fnd.vypl_pen   vp
where  1=1
and    vp.tip_vypl in (1, 3, 6, 91)
and    vp.data_nachisl = to_date(20180601, 'yyyymmdd')
and    (vp.nom_vkl, vp.nom_ips) in (
         select /*+ materialize doc.nom_vkl, doc.nom_ips
          from   assignments    a,
                 fnd.sp_pen_dog doc
          where  1=1
          and    doc.ref_kodinsz = a.fk_doc_with_acct
          and    a.fk_doc_with_action = 23236674
       )
*/
select count(1) from (
/*select doc.ref_kodinsz--, vp.summa
from   fnd.vypl_pen   vp,
       fnd.sp_pen_dog doc
where  1=1
and    exists(select 1 from )
and    vp.nom_vkl = doc.nom_vkl
and    vp.nom_ips = doc.nom_ips
and    vp.tip_vypl in (1, 3, 6, 91)
and    vp.data_nachisl = to_date(20180601, 'yyyymmdd')
minus  --*/ 
select a.fk_doc_with_acct--, a.amount --, 2) amount
from   assignments a
where  1=1
and    a.fk_doc_with_action = 23236674
 minus
select doc.ref_kodinsz --, vp.summa --, 2) amount
from   fnd.vypl_pen   vp,
       fnd.sp_pen_dog doc
where  vp.nom_vkl = doc.nom_vkl
and    vp.nom_ips = doc.nom_ips
and    vp.tip_vypl in (1, 3, 6, 91)
and    vp.data_nachisl = to_date(20180601, 'yyyymmdd') --*/
)
/
select count(1)--a.fk_doc_with_acct, a.amount, doc.nom_vkl, doc.nom_ips, vp.ssylka_fl, vp.summa, a.amount - vp.summa diff_gf_fnd
from   assignments a,
       fnd.sp_pen_dog doc,
       fnd.vypl_pen   vp
where  1=1
--and    not exists(select 1 from pension_agreement_addendums paa where paa.fk_pension_agreement = a.fk_doc_with_acct and paa.creation_date> to_date(20180609, 'yyyymmdd'))
and    a.amount = vp.summa
and    vp.tip_vypl in (1, 3, 6, 91)
and    vp.data_nachisl = to_date(20180601, 'yyyymmdd')
and    vp.nom_vkl = doc.nom_vkl
and    vp.nom_ips = doc.nom_ips
and    doc.ref_kodinsz = a.fk_doc_with_acct
and    a.fk_doc_with_action = 23236674
/
select count(1)--a.fk_doc_with_acct, a.amount, doc.nom_vkl, doc.nom_ips, vp.ssylka_fl, vp.summa, a.amount - vp.summa diff_gf_fnd
from   assignments a
where  1=1
and    a.fk_doc_with_action = 23236674
