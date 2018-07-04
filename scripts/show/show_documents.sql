with docs as (
select vp.ssylka_doc,
       vp.data_op      date_op
from   vbz_pay_contragents c,
       fnd.vypl_pen        vp
where  1=1
and    vp.data_op < to_date(20180401, 'yyyymmdd')
and    vp.nom_ips = c.nom_ips
and    vp.nom_vkl = c.nom_vkl
group by vp.ssylka_doc, vp.data_op
)
select fd.date_op,
       d.*
from   docs                fd,
       fnd.reer_doc_ngpf   rdn,
       documents           d
where  1=1
and    d.id = rdn.ref_kodinsz
and    rdn.ssylka = fd.ssylka_doc
order by fd.date_op
