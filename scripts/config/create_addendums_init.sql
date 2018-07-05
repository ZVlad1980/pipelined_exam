insert into	pension_agreement_addendums(
  id,
  fk_pension_agreement,
  fk_base_doc,
  fk_provacct,
  serialno,
  canceled,
  amount,
  alt_date_begin
) select pension_agreement_addendum_seq.nextval,
         t.fk_contract,
         t.fk_contract,
         null,
         0,
         0,
         t.amount,
         t.effective_date
  from   (select spd.ssylka,
                 cn.fk_document fk_contract,
                 sfl.gf_person,
                 spd.nom_vkl,
                 spd.shema_dog,
                 spd.razm_pen,
                 spd.data_nach_vypl,
                 cn.fk_contragent,
                 cn.fk_company,
                 cn.fk_scheme,
                 pa.effective_date,
                 pa.amount,
                 bcn.fk_account fk_debet,
                 cn.fk_account fk_credit,
                 (select count(1) from pension_agreement_addendums paa where paa.fk_pension_agreement = pa.fk_contract) add_cnt --*/
          from   fnd.sp_pen_dog spd,
                 fnd.sp_fiz_lits sfl,
                 contracts      cn,
                 pension_agreements pa,
                 contracts      bcn
          where  1=1
          and    bcn.fk_document = pa.fk_base_contract
          --and    cn.fk_company = 50
          and    cn.fk_scheme <> 7
          and    cn.fk_company <> 1001
          --and    pa.amount <> spd.razm_pen
          and    pa.isarhv = 0
          and    pa.state = 1
          and    pa.fk_contract = cn.fk_document
          --and    cn.cntr_state = 10
          and    cn.fk_cntr_type = 6
          and    cn.fk_document = spd.ref_kodinsz
          and    sfl.ssylka = spd.ssylka
        ) t
/
/*select *
from   pension_agreement_addendums paa 
where  paa.fk_pension_agreement = 11661564
order by paa.serialno
*/
