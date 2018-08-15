select ipd.ssylka_fl, ipd.nom_izm, ipd.data_izm
from   fnd.sp_izm_pd ipd
where  ipd.ssylka_fl = 186
/--minus
select pd.ssylka, paa.serialno, paa.alt_date_begin
from   pension_agreements_v pa,
       fnd.sp_pen_dog_v     pd,
       pension_agreement_addendums paa
where  pd.ref_kodinsz = pa.fk_contract
and    paa.fk_pension_agreement = pa.fk_contract
and    pd.ssylka = 186
/
select *
from   fnd.sp_pen_dog_v     pd
where  pd.ssylka = 186
