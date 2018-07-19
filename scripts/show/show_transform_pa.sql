select tpa.ssylka_fl       ,
       tpa.date_nach_vypl  ,
       tpa.fk_base_contract,
       tpa.fk_contragent   ,
       tpa.ref_kodinsz     ,
       tpa.fk_contract     ,
       tpa.source_table    ,
       --
       pd.cntr_print_date,
       pd.data_arh             cntr_close_date,
       tpa.ref_kodinsz         fk_document,
       'Пенсионное соглашение: '||trim(to_char(pd.nom_vkl, '0000'))||'/'||trim(to_char(pd.ssylka, '0000000')) as doctitle,
       pd.cntr_date,
       pd.ref_kodinsz cntr_nbr,
       6 cntr_type,
       pd.nom_vkl fk_company,
       pd.shema_dog fk_cntr_scheme,
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
where  1=1
and    lspv.ssylka_fl = pd.ssylka
and    pd.data_nach_vypl = tpa.date_nach_vypl
and    pd.ssylka = tpa.ssylka_fl
and    not exists (
         select 1
         from   pension_agreements pa
         where  pa.fk_base_contract = tpa.fk_base_contract
         and    pa.effective_date = tpa.date_nach_vypl
       )
/
select *
from   transform_pa      tpa,
       documents         d
where  d.id = tpa.ref_kodinsz
