select tc.fk_contragent,
       tc.fk_contract,
       tc.title,
       d.id doc_id,
       d.fk_operator doc_fk_operator,
       pd.contract_count,
       (select count(1) from fnd.sp_invalid_v inv where inv.ssylka_fl = pd.ssylka) inv_count,
       pd.source_table, 
       pd.nom_vkl, 
       pd.nom_ips, 
       pd.fio, 
       pd.data_arh, 
       pd.data_otkr, 
       pd.ssylka, 
       pd.data_nach_vypl, 
       pd.data_okon_vypl,
       p.deathdate,
       pd.razm_pen, 
       pd.data_uvoln, 
       pd.shema_dog, 
       pd.data_perevoda_5_cx, 
       pd.ref_kodinsz, 
       pd.kod_insz, 
       pd.summa_perevoda_5_cx
from   (
        select pd.source_table, 
               pd.nom_vkl, 
               pd.nom_ips, 
               pd.fio, 
               pd.data_arh, 
               pd.data_otkr, 
               pd.ssylka, 
               pd.data_nach_vypl, 
               trunc(least(
                 coalesce(pd.data_okon_vypl, sysdate), 
                 coalesce(pd.data_okon_vypl_next, sysdate),
                 coalesce(inv.pereosv, sysdate)
               )) data_okon_vypl,
               pd.razm_pen, 
               pd.data_uvoln, 
               pd.shema_dog, 
               pd.data_perevoda_5_cx, 
               pd.ref_kodinsz, 
               pd.kod_insz, 
               pd.summa_perevoda_5_cx,
               count(pd.ssylka) over(partition by pd.ssylka) contract_count
        from   fnd.sp_pen_dog_v pd,
               fnd.sp_invalid_v inv
        where  1=1
        and    exists (
                 select 1
                 from   fnd.vypl_pen vp
                 where  1=1
                 and    vp.data_nachisl between pd.data_nach_vypl and least(coalesce(inv.pereosv, sysdate), coalesce(pd.data_okon_vypl_next, sysdate))--
                 --and    vp.data_op between to_date(20180601/*19800101*/, 'yyyymmdd') and to_date(20180630, 'yyyymmdd')
                 and    vp.ssylka_fl = pd.ssylka
               )
        and    inv.pereosv(+) between pd.data_nach_vypl and coalesce(pd.data_okon_vypl_next, sysdate)--
        and    inv.ssylka_fl(+) = pd.ssylka
       ) pd,
       documents d,
       lateral(
         select tc.fk_contract,
                tc.fk_contragent,
                d.id fk_document,
                d.title
         from   transform_contragents tc,
                documents             d
         where  1=1
         and    d.id(+) = tc.fk_contract
         and    tc.ssylka_fl = pd.ssylka
       ) (+) tc,
       people p
where   1 = 1
and     p.fk_contragent(+) = tc.fk_contragent
and     d.id(+) = pd.ref_kodinsz
and     not exists (
          select 1
          from   pension_agreements    pa,
                 contracts             cn
          where  1 = 1
          and    cn.fk_document = pa.fk_contract
          and    pa.effective_date = pd.data_nach_vypl
          and    pa.fk_base_contract = tc.fk_contract
        )
order by pd.ssylka, pd.data_nach_vypl
/
