create or replace view izmeneniya_pd_v as
select ik.val ssylka_fl_str,
       iz.nom_izm,
       iz.kod_izm,
       iz.kod_doc,
       iz.kod_oper,
       iz.data_otrab,
       iz.data_zanes,
       iz.kod_sost,
       ss.soderg
from   izmeneniya  iz,
       izm_key_val ik,
       izm_spr_soderg ss
where  1=1
and    ss.kod_izm = iz.kod_izm
and    iz.nom_izm = ik.nom_izm
and    ik.nom_trans = 1
and    ik.fld_nom = 1
/
grant select on izmeneniya_pd_v to gazfond
/
