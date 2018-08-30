select iz.*,
       ik.val,
       id.kod_dat,
       id.old_val,
       id.new_val
from   izmeneniya  iz,
       izm_key_val ik,
       izm_data    id
where  1=1
and    id.nom_izm = iz.nom_izm
and    iz.kod_izm in (12,24,72,73) --(11)
and    iz.nom_izm = ik.nom_izm
and    ik.nom_trans = 1
and    ik.fld_nom = 1
and    ik.val = '60130'
