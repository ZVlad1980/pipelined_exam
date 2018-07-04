/*
--drop table vbz_pay_contragents;
create table vbz_pay_contragents as
select c.fk_document fk_contract,
       pa.effective_date,
       c.fk_scheme,
       p.fk_contragent,
       fl.ssylka, fl.nom_vkl, fl.nom_ips, -- fl.last_nAME || ' ' || fl.first_name || ' ' || fl.second_name fl_full_name, fl.birth_date fl_birth_date,
       p.fullname, p.birthdate,
       c.fk_company,
       cp.short_name company_name,
       cp.title      company_title
from   contracts c,
       pension_agreements pa,
       people    p,
       lateral(
         select fl.*
         from   fnd.sp_fiz_litz_lspv_v fl
         where  fl.gf_person = p.fk_contragent
         and    fl.pen_scheme_code = c.fk_scheme
       ) fl,
       companies cp
where  1=1
and    cp.fk_contragent = c.fk_company
and    p.fk_contragent = c.fk_contragent
and    pa.isarhv = 0
and    pa.state = 1
and    pa.fk_contract = c.fk_document
and    c.fk_cntr_type = 6
and    c.fk_company = 50
*/
select c.ssylka,
       c.nom_vkl,
       c.nom_ips,
       c.fk_scheme,
       bcn.fk_account fk_debit,
       cn.fk_account  fk_credit,
       c.fk_contragent,
       c.fk_contract,
       c.effective_date,
       vp.data_nachisl,
       vp.data_op,
       vp.Tip_Vypl,
       vp.oplach_dni,
       vp.polucheno,
       vp.udergano,
       vp.polucheno + nvl(vp.udergano, 0) nach_amount,
       vp.uderg_nr,
       vp.ssylka_doc,
       pa.expiration_date
from   vbz_pay_contragents c,
       fnd.vypl_pen        vp,
       fnd.reer_doc_ngpf   rdn,
       pension_agreements  pa,
       contracts           cn,
       contracts           bcn
where  1=1
and    bcn.fk_document = pa.fk_base_contract
and    cn.fk_document = pa.fk_contract
and    pa.fk_contract = c.fk_contract
and    rdn.ssylka = vp.ssylka_doc
and    vp.data_nachisl = to_date(20180401, 'yyyymmdd')
and    vp.nom_ips = c.nom_ips
and    vp.nom_vkl = c.nom_vkl
order by vp.data_op, vp.nom_ips
/
select paa.id, paa.alt_date_begin, paa.creation_date, paa.amount, paa.canceled, pa.*
from   pension_agreements pa,
       pension_agreement_addendums paa
where  paa.fk_pension_agreement(+) = pa.fk_contract
and    pa.fk_contract in (
13545579,
13464073,
19297505,
13470830,
19285579,
19332286,
19280206,
15786317,
22944894,
22880500,
22867025,
22931907
)
order by pa.fk_contract, paa.alt_date_begin, paa.serialno
