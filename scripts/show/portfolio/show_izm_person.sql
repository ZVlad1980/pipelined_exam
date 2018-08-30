/*with w_not_found as (
select tpa.ssylka_fl,
       tpa.date_nach_vypl
from   transform_pa    tpa
where  tpa.fk_contract is not null
minus--
select --count(1)/*
       t.ssylka_fl,
       t.date_nach_vypl
from  (--*/
/*select tpa.ssylka_fl,
       tpa.date_nach_vypl,
       tpa.source_table,
       trunc(pd.data)                pd_creation_date,
       min(trunc(iz.data_zanes))     change_date,
       min(iz.kod_izm)               min_kod_izm,
       max(iz.kod_izm)               max_kod_izm,
       min(iz.kod_doc)               min_kod_doc,
       max(iz.kod_doc)               max_kod_doc,
       min(trunc(iz.data_zanes) - 
         trunc(pd.data)
       )                             min_diff,
       max(trunc(iz.data_zanes) - 
         trunc(pd.data)
       )                             max_diff,
       min(iz.nom_izm)               min_nom_izm --*/
select t.ssylka_fl,
       t.date_nach_vypl,
       fl.familiya || ' ' || fl.imya || ' ' || fl.otchestvo || ' (' || to_char(fl.data_rogd, 'dd.mm.yyyy') || ')' fio,
       rdi.num_from,
       rdi.dept_from,
       rdi.folder_from,
       t.source_table,
       t.pd_creation_date,
       t.change_date,
       t.kod_izm,
       t.kod_doc,
       t.nom_izm,
       t.true_kod_izm
from   (
         select tpa.ssylka_fl,
                tpa.date_nach_vypl,
                tpa.source_table,
                trunc(pd.data) pd_creation_date,
                trunc(iz.data_zanes) change_date,
                iz.kod_izm,
                iz.kod_doc,
                iz.nom_izm,
                case 
                  when iz.kod_izm in (12, 24, 66, 68, 81, 85, 87, 88, 89, 90, 92, 107, 109, 72, 73) then 'Y'
                  else 'N'
                end true_kod_izm,
                row_number() over (partition by tpa.ssylka_fl, tpa.date_nach_vypl
                  order by case when iz.kod_izm in (12, 24, 66, 68, 81, 85, 87, 88, 89, 90, 92, 107, 109, 72, 73) then 0 --прямой код изменения
                    else 1000 --обходной код
                    end + to_number(abs(iz.data_zanes - pd.data)) + (iz.kod_izm / 100)
                  ) rn
         from   transform_pa         tpa,
                fnd.sp_pen_dog_imp_v pd,
                fnd.izmeneniya_pd_v  iz
         where  1=1
         and    (
                  (iz.kod_izm in (12, 24, 66, 68, 81, 85, 87, 88, 89, 90, 92, 107, 109, 72, 73)
                  )
                 or
                  (
                   exists (
                     select 1
                     from   fnd.izmeneniya       iz2
                     where  iz2.kod_doc = iz.kod_doc
                     and    iz2.kod_izm in (12, 24, 66, 68, 81, 85, 87, 88, 89, 90, 92, 107, 109, 72, 73)
                   )
                  )
                )
         and    abs(iz.data_zanes - pd.data) < 10
         and    iz.ssylka_fl_str = to_char(pd.ssylka)
         and    pd.data_nach_vypl = tpa.date_nach_vypl
         and    pd.ssylka = tpa.ssylka_fl
         --and    tpa.ssylka_fl = &ssylka
       ) t,
       fnd.reg_doc_insz rdi,
       fnd.sp_fiz_lits  fl
where t.rn = 1
and   rdi.kod_insz = t.kod_doc
and   fl.ssylka = t.ssylka_fl
