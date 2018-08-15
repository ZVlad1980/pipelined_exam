select count(1)
from   fnd.sp_izm_pd ipd
      join fnd.reer_doc_ngpf rdn
      on   rdn.ssylka = ipd.ssylka_doc
      /*join fnd.sp_pen_dog_v pd
      on   pd.ssylka = ipd.ssylka_fl
      and  ipd.data_izm between pd.data_nach_vypl and nvl(pd.data_okon_vypl, ipd.data_izm)
      and  pd.shema_dog in (1,2,3,4,5,6,8) --*/
where rdn.kod_insz is null
/
select rdn.nom_doc,rdn.kr_soderg,
       rdn.kod_sr,
       rdn.kod_insz,
       rdn.ref_kodinsz,
       d.fk_file,
       d.title,
       fs.old_file_name,
       rd.fk_file rd_fk_file,
       rd.title   rd_title,
       rfs.old_file_name
from   fnd.reer_doc_ngpf rdn,
       documents         d,
       filestorages      fs,
       documents         rd,
       filestorages      rfs
where  rdn.kod_insz <> rdn.ref_kodinsz
and    d.id(+) = rdn.kod_insz
and    fs.id(+) = d.fk_file
and    rd.id(+) = rdn.ref_kodinsz
and    rfs.id(+) = rd.fk_file
/
