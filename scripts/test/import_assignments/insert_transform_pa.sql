/*
truncate table ERR$_IMP_DOCUMENTS;
truncate table ERR$_IMP_CONTRACTS;
truncate table ERR$_IMP_PENSION_AGREEMENTS;
*/
select * from contracts c where c.fk_document in (2602983, 6438211);

select * from ERR$_IMP_DOCUMENTS t where t.ora_err_tag$ = 'Import PA: 20180720090440';
select * from ERR$_IMP_CONTRACTS t where t.ora_err_tag$ = 'Import PA: 20180720090440';
select * from ERR$_IMP_PENSION_AGREEMENTS t where t.ora_err_tag$ = 'Import PA: 20180720090440';

insert all
  when doc_exists = 'N' and ref_kodinsz is not null then
    into documents(id, fk_doc_type, doc_date, title, fk_doc_with_acct)
    values(ref_kodinsz, 2, cntr_date, doctitle, ref_kodinsz)
    log errors into ERR$_IMP_DOCUMENTS reject limit unlimited
  when cntr_exists = 'N' then
    into contracts(fk_document, cntr_number, cntr_index, cntr_date, title, fk_cntr_type, fk_workplace, fk_contragent,  fk_company, fk_scheme, fk_closed)
    values(ref_kodinsz, cntr_number, cntr_index,cntr_date, doctitle, 6, 100001, fk_contragent, fk_company, fk_scheme, null)
    log errors into ERR$_IMP_CONTRACTS reject limit unlimited
  when 1 = 1 then
    into pension_agreements(fk_contract, effective_date, expiration_date, amount, delta_pen, fk_base_contract, period_code, years, state, isarhv)
    values (ref_kodinsz, date_nach_vypl, data_okon_vypl, razm_pen, delta_pen, fk_base_contract, period_code, years, state, isarhv)
    log errors into ERR$_IMP_PENSION_AGREEMENTS (&err_tag) reject limit unlimited
select t.doc_exists,
       t.cntr_exists,
       t.fk_base_contract,
       t.ref_kodinsz,
       t.cntr_date,
       t.cntr_number,
       t.cntr_index,
       t.doctitle,
       t.fk_contragent,
       t.fk_company,
       t.fk_scheme,
       t.date_nach_vypl,
       t.data_okon_vypl,
       t.razm_pen,
       t.delta_pen,
       t.period_code,
       t.years,
       t.state,
       t.isarhv
from   (
select tpa.ssylka_fl       ,
       tpa.date_nach_vypl  ,
       tpa.fk_base_contract,
       tpa.fk_contragent   ,
       tpa.ref_kodinsz     ,
       tpa.fk_contract     ,
       tpa.source_table    ,
       case
         when exists(
                select 1
                from   documents d2
                where  d2.id = tpa.ref_kodinsz
              )
           then 'Y' 
         else   'N' 
       end                  doc_exists,
       case
         when exists(
                select 1
                from   contracts cn2
                where  cn2.fk_document = tpa.ref_kodinsz
              )
           then 'Y' 
         else   'N' 
       end                  cntr_exists,
       --
       tpa.ssylka_fl cntr_number,
       lpad(row_number()over(partition by tpa.ssylka_fl order by tpa.ssylka_fl, tpa.date_nach_vypl) + (select coalesce(count(1), 0) from contracts cn2 where cn2.cntr_number = tpa.ssylka_fl and cn2.fk_cntr_type = 6), 2, '0') cntr_index,
       pd.cntr_print_date,
       pd.data_arh             cntr_close_date,
       tpa.ref_kodinsz         fk_document,
       'Пенсионное соглашение: '||trim(to_char(pd.nom_vkl, '0000'))||'/'||trim(to_char(pd.ssylka, '0000000')) as doctitle,
       pd.cntr_date,
       6 cntr_type,
       pd.nom_vkl fk_company,
       pd.shema_dog fk_scheme,
       pd.data_nach_vypl,
       pd.data_okon_vypl,
       pd.razm_pen,
       pd.delta_pen,
       nvl(pd.id_period_payment, 0) period_code,
       case 
         when pd.id_period_payment <> 0 and pd.data_okon_vypl is not null then extract(year from pd.data_okon_vypl) - extract(year from pd.data_nach_vypl)
         else null
       end                                  years,
       case
         when pd.source_table = 'SP_PEN_DOG_ARH' then
           2
         when lspv.status_pen in ('п', 'и') then 1
         when lspv.status_pen = 'о' then 2
         else 0 
       end as                               state,
       case when pd.source_table = 'SP_PEN_DOG_ARH' then 1 else 0 end isarhv
from   transform_pa      tpa,
       fnd.sp_pen_dog_v  pd,
       fnd.sp_lspv       lspv
where  1=1--rownum < 50 --=1
and    lspv.ssylka_fl = pd.ssylka
and    pd.data_nach_vypl = tpa.date_nach_vypl
and    pd.ssylka = tpa.ssylka_fl
and    not exists (
         select 1
         from   pension_agreements pa
         where  pa.fk_base_contract = tpa.fk_base_contract
         and    pa.effective_date = tpa.date_nach_vypl
       )
and    tpa.fk_contract is null
and    tpa.ref_kodinsz is null
order by tpa.ssylka_fl,
       tpa.date_nach_vypl
) t
