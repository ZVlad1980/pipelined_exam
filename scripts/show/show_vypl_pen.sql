select *--distinct vp.tip_vypl--count(1)
from   vypl_pen vp
where  1=1
and    vp.data_op between to_date(20180501, 'yyyymmdd') and to_date(20180531, 'yyyymmdd')
/
select *
from   dv_sr_ips d
where  d.ssylka_doc = 823961
/
select *
from   reer_doc_ngpf doc
where  doc.ssylka = 823961
