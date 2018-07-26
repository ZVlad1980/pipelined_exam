select cn.cntr_number, pa.*--pa.state, pa.effective_date, pa.expiration_date, d.*
from   pension_agreements pa,
       contracts          cn,
       documents          d
where  1=1
--and    cn.fk_account is not null
and    d.id = cn.fk_document
and    cn.fk_scheme in (1,2,3,4,5,6,8)
and    cn.fk_document = pa.fk_contract
and    pa.fk_base_contract in (
        select pa2.fk_base_contract
        from   pension_agreements pa2
        where  1=1
        and    pa2.fk_base_contract = 2592430
        and    exists (
                 select 1
                 from   pension_agreements pa3
                 where  pa3.fk_base_contract = pa2.fk_base_contract
                 and    pa3.fk_contract <> pa2.fk_contract
               )
        --and    pa2.creation_date between to_date(20180716, 'yyyymmdd') and to_date(20180722, 'yyyymmdd')
       )
/
select *
from   accounts a
where  a.id = 12493031
/
select *
from   fnd.sp_pen_dog pd
where  pd.ssylka = 583
/
select *
from   fnd.sp_pen_dog_arh pd
where  pd.ssylka = 583
/
select *
from   fnd.vypl_pen vp
where  vp.ssylka_fl = 583
order by vp.data_nachisl
