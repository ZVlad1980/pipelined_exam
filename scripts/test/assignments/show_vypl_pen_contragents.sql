select c.fk_document fk_contract,
       c.title,
       sfl.familiya || ' ' || sfl.imya || ' ' || sfl.otchestvo fio,
       pa.effective_date,
       vp.*
from   fnd.vypl_pen         vp,
       fnd.sp_fiz_lits      sfl,
       contracts            c,
       pension_agreements   pa
where  1=1
and    vp.tip_vypl = 1
and    pa.fk_contract = c.fk_document
and    c.fk_company = sfl.nom_vkl
and    c.fk_scheme = sfl.pen_sxem
and    c.fk_cntr_type = 6
and    c.fk_contragent = sfl.gf_person
and    sfl.ssylka = vp.ssylka_fl
and    vp.nom_ips in (180, 174, 175, 172)
and    vp.nom_vkl = 50
and    vp.ssylka_doc = 818763 --C_SSYLKA_DOC
order by vp.data_op, vp.data_nachisl
