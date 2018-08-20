create or replace package body import_addendums is

-- первоначальный импорт
procedure primary_import is
begin
  import_assignments_pkg.import_pa_addendums;
  return;
insert into pension_agreement_addendums t 
(t.fk_pension_agreement, t.fk_base_doc, t.fk_provacct, t.serialno, t.amount, t.alt_date_begin, t.creation_date)
(
select pag.fk_contract fk_pension_agreement, rdn.kod_insz fk_base_doc, 
       case when co.fk_scheme = 1 then PROV_ACCT_SCH_1 when co.fk_scheme = 6 then PROV_ACCT_SCH_6 else a.id end  fk_prov_acct, 
       ipd.nom_izm serialno, ipd.summa_izm amount, ipd.data_izm alt_date_begin, ipd.dat_zanes creation_date
from fnd.sp_izm_pd ipd
     join transform_contragents tc on tc.ssylka_fl = ipd.ssylka_fl
     join pension_agreements pag on pag.fk_base_contract = tc.fk_contract
     join contracts co on co.fk_document = pag.fk_base_contract
     join fnd.reer_doc_ngpf rdn on rdn.ssylka = ipd.ssylka_doc
     join documents d on d.id = rdn.kod_insz
     left join accounts a on a.id = co.fk_account
     );
end;
--895549
-- последующая дозагрузка (если в FND добавились новые изменения ПД)
procedure incremental_import is
begin
  import_assignments_pkg.import_pa_addendums;
  return;
  insert into pension_agreement_addendums t(t.fk_pension_agreement, t.fk_base_doc, t.fk_provacct, t.serialno, t.amount, t.alt_date_begin, t.creation_date)
  (
  select pa.fk_contract fk_pension_agreement, rdn.kod_insz fk_base_doc, 
  case when co.fk_scheme = 1 then PROV_ACCT_SCH_1 when co.fk_scheme = 6 then PROV_ACCT_SCH_6 else a.id end fk_prov_acct,
    ipd.nom_izm serialno, ipd.summa_izm amount, ipd.data_izm alt_date_begin, ipd.dat_zanes creation_date
  from fnd.sp_izm_pd ipd
       join transform_contragents tc on tc.ssylka_fl = ipd.ssylka_fl
       join pension_agreements pa on pa.fk_base_contract= tc.fk_contract
       left join pension_agreement_addendums pad on pad.fk_pension_agreement = pa.fk_contract and pad.serialno = ipd.nom_izm
       join contracts co on co.fk_document = pa.fk_base_contract
       join fnd.reer_doc_ngpf rdn on rdn.ssylka = ipd.ssylka_doc
       join documents d on d.id = rdn.kod_insz
       left join accounts a on a.id = co.fk_account
  where pad.fk_pension_agreement is null
  );
end;

-- процедура простановки значений поля canceled в pension_agreement_addendums
procedure update_canceled is
begin
  import_assignments_pkg.import_pa_addendums;
  return;
  update pension_agreement_addendums tt set canceled = 
    nvl((select nom_max from(
        select distinct ipd.ssylka_fl, pad.fk_pension_agreement, ipd.nom_izm, 
                max(ipd1.nom_izm) over (partition by ipd.ssylka_fl, ipd.nom_izm) nom_max
        from fnd.sp_izm_pd ipd, fnd.sp_izm_pd ipd1,
        transform_contragents tc,
        pension_agreement_addendums pad,
        pension_agreements pa 
        where (ipd.ssylka_fl,ipd.nom_izm)in
          ( select ssylka_fl, nom_izm from  fnd.sp_izm_pd ipd 
          where exists(select nom_izm, data_izm from fnd.sp_izm_pd  
          where ssylka_fl = ipd.ssylka_fl and nom_izm > ipd.nom_izm and data_izm <=  ipd.data_izm))
        and ipd1.ssylka_fl = ipd.ssylka_fl 
        and ipd1.nom_izm > ipd.nom_izm and ipd1.data_izm <= ipd.data_izm
        and tc.ssylka_fl = ipd.ssylka_fl
        and pa.fk_base_contract = tc.fk_contract
        and pa.fk_contract = pad.fk_pension_agreement
        and tt.fk_pension_agreement = pa.fk_contract
        and tt.serialno = ipd.nom_izm
        )),
      0)
    where exists(select nom_izm, data_izm from fnd.sp_izm_pd ttt,
      transform_contragents tc,
      pension_agreements pa  
      where tc.ssylka_fl = ttt.ssylka_fl and pa.fk_base_contract = tc.fk_contract 
        and pa.fk_contract = tt.fk_pension_agreement and ttt.nom_izm > tt.serialno and ttt.data_izm <=  tt.alt_date_begin);
end;
--23942

-- удаление всех pension_agreement_addendums для НПО
procedure  delete_all_addendums is
begin
  delete from pension_agreement_addendums pad where pad.id in
  (
    select pad.id from pension_agreement_addendums pad
    join pension_agreements pa on pa.fk_contract = pad.fk_pension_agreement
    join contracts co on co.fk_document = pa.fk_base_contract
    where co.fk_cntr_type in (2,3)
  );
end;  

begin
  -- Initialization
  null;
end import_addendums;
/
