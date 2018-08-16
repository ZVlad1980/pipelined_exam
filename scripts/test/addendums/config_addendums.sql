create global temporary table pa_tmp(
  fk_base_contract number(10),
  fk_contract      number(10),
  effective_date   date
) on commit preserve rows
/
insert into pa_tmp(
  fk_base_contract,
  fk_contract     ,
  effective_date  
) select pa.fk_base_contract,
         pa.fk_contract,
         pa.effective_date
  from   (select pa.fk_base_contract,
                 pa.fk_contract,
                 pa.effective_date,
                 count(1)over(partition by pa.fk_base_contract) cnt,
                 row_number()over(partition by pa.fk_base_contract order by pa.effective_date) rn
          from   pension_agreements_v        pa
         ) pa
  where  pa.cnt = pa.rn
  and    pa.cnt > 1
  and    exists (
           select 1
           from   pension_agreement_addendums paa
           where  paa.fk_pension_agreement = pa.fk_contract
           and    paa.alt_date_begin < pa.effective_date
         )
/
select pa.*,
       paa.*
from   (
        select pa.fk_base_contract,
               pa.fk_contract,
               pa.effective_date,
               lead(pa.effective_date)over(partition by pa.fk_base_contract order by pa.effective_date) - 1 expiration_date,
               pat.fk_contract    last_fk_contract,
               pat.effective_date last_effective_date
        from   pa_tmp             pat,
               pension_agreements pa
        where  pa.fk_base_contract = pat.fk_base_contract
       ) pa,
       pension_agreement_addendums paa
where  1=1
and    pa.fk_base_contract = 2595283
and    paa.alt_date_begin between pa.effective_date and pa.expiration_date
and    paa.fk_pension_agreement = pa.last_fk_contract
and    pa.fk_contract <> pa.last_fk_contract
/
merge into pension_agreement_addendums paa
using ( select paa.id,
               pa.fk_contract
        from   (
                select pa.fk_base_contract,
                       pa.fk_contract,
                       pa.effective_date,
                       lead(pa.effective_date)over(partition by pa.fk_base_contract order by pa.effective_date) - 1 expiration_date,
                       pat.fk_contract    last_fk_contract,
                       pat.effective_date last_effective_date
                from   pa_tmp             pat,
                       pension_agreements pa
                where  pa.fk_base_contract = pat.fk_base_contract
               ) pa,
               pension_agreement_addendums paa
        where  1=1
        and    paa.alt_date_begin between pa.effective_date and pa.expiration_date
        and    paa.fk_pension_agreement = pa.last_fk_contract
        and    pa.fk_contract <> pa.last_fk_contract
      ) pa
on    ( paa.id = pa.id
      )
when matched then
  update set
    paa.fk_pension_agreement = pa.fk_contract
log errors into ERR$_PENSION_AGREEMENT_ADDEND reject limit unlimited
/
delete from pension_agreement_addendums paa
where  paa.id in (
         select e.id
         from   ERR$_PENSION_AGREEMENT_ADDEND e
         where  e.ora_err_mesg$ like 'ORA-00001: unique constraint (GAZFOND.PENSION_AGREEMENT_ADDENDUM_UK) violated%'
       )
/
drop table pa_tmp
/
insert into  pension_agreement_addendums(
  id,
  fk_pension_agreement,
  fk_base_doc,
  fk_provacct,
  serialno,
  canceled,
  amount,
  alt_date_begin
)
select pension_agreement_addendum_seq.nextval,
       pa.fk_contract,
       pa.fk_contract,
       null,
       0,
       0,
       pa.pa_amount,
       pa.effective_date
from   (select pa.fk_base_contract,
               pa.fk_contract,
               pa.effective_date,
               pa.pa_amount,
               pa.fk_scheme,
               pa.fk_contragent,
               count(1)over(partition by pa.fk_base_contract) cnt,
               row_number()over(partition by pa.fk_base_contract order by pa.effective_date) rn
        from   pension_agreements_v        pa
       ) pa
where  pa.cnt = pa.rn
and    not exists (
         select 1
         from   pension_agreement_addendums paa
         where  paa.fk_pension_agreement = pa.fk_contract
         and    paa.alt_date_begin <= pa.effective_date
       )
/
commit
/
/*
delete from pension_agreement_addendums a
where  a.serialno = 0
/
insert into pension_agreement_addendums(
  id,
  fk_pension_agreement,
  fk_base_doc,
  fk_provacct,
  serialno,
  canceled,
  amount,
  alt_date_begin,
  alt_date_end,
  creation_date
)
select *
from   pension_agreement_addendums@gf_fonddb a
where  a.fk_pension_agreement in (
       	 select asg.fk_doc_with_acct
         from   assignments asg
         where  asg.fk_doc_with_action = 23236674
       )
/
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
                 (select count(1) from pension_agreement_addendums paa where paa.fk_pension_agreement = pa.fk_contract) add_cnt 
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
          --and    spd.ref_kodinsz = 15769810
          and    sfl.ssylka = spd.ssylka
        ) t
/
commit
*/
