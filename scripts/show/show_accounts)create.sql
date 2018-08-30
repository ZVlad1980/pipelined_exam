/*
select cn.fk_document,
       cn.cntr_number,
       cn.fk_contragent,
       pa.effective_date,
       pa.expiration_date
from   contracts          cn,
       pension_agreements pa,
       fnd.sp_pen_dog_v   pd
where  1 = 1
and    
and    pd.data_nach_vypl = pa.effective_date
and    pd.ref_kodinsz = cn.fk_document
and    cn.fk_account is null
and    pa.fk_contract = cn.fk_document
and    cn.fk_scheme in (1, 2, 3, 4, 5, 6, 8)
and    cn.fk_cntr_type = 6
*/
select count(1) from (
select pd.ssylka, 
       pd.data_nach_vypl,
       pd.ref_kodinsz,
       pd.source_table,
       lspv.nom_vkl lspv_nom_vkl,
       lspv.nom_ips lspv_nom_ips,
       pa.fk_base_contract,
       pa.fk_contract,
       pa.effective_date,
       pa.expiration_date,
       pa.state,
       pa.isarhv,
       pa.cntr_number
from   fnd.sp_pen_dog_v      pd,
       fnd.sp_lspv           lspv,
       fnd.sp_invalid_v      inv,
       transform_contragents tc,
       lateral(
         select pa.fk_base_contract,
                pa.fk_contract,
                pa.effective_date,
                pa.expiration_date,
                pa.state,
                pa.isarhv,
                cn.cntr_number
         from   pension_agreements    pa,
                contracts             cn
         where  1=1
         and    cn.fk_account is null
         and    cn.fk_document = pa.fk_contract
         and    pa.effective_date = pd.data_nach_vypl
         and    pa.fk_base_contract = tc.fk_contract
       ) (+) pa
where  1=1 
and    lspv.ssylka_fl = pd.ssylka
and    tc.ssylka_fl = pd.ssylka
and    exists (
         select 1
         from   fnd.vypl_pen vp
         where  1=1
         and    vp.data_nachisl between pd.data_nach_vypl and least(coalesce(inv.pereosv, sysdate), coalesce(pd.data_okon_vypl_next, sysdate))--
         and    vp.data_op between &p_from_date and &p_to_date
         and    vp.ssylka_fl = pd.ssylka
       )
and    inv.pereosv(+) between pd.data_nach_vypl and coalesce(pd.data_okon_vypl_next, sysdate)--
and    inv.ssylka_fl(+) = pd.ssylka
)
