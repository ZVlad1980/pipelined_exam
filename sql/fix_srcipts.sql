update transform_contragents tc
set    tc.ssylka_fl = 297214
where  tc.fk_contract = 1695647
/
begin
  for rec in (select pa.fk_contract,
                     spd.ssylka
              from   pension_agreements    pa,
                     contracts             cs,
                     transform_contragents tc,
                     fnd.sp_pen_dog        spd
              where  pa.fk_base_contract = cs.fk_document
              and    cs.fk_document = tc.fk_contract
              and    tc.ssylka_fl = spd.ssylka
              and    spd.ref_kodinsz is null
              and    spd.data_nach_vypl = pa.effective_date
              and    spd.razm_pen = pa.amount) loop
    update fnd.sp_pen_dog
    set    ref_kodinsz = rec.fk_contract
    where  ssylka = rec.ssylka;
  end loop;
end;
/
select *
from   fnd.sp_pen_dog     spd,
       pension_agreements pa
where  spd.shema_dog <> 7 /*7-я схема ОПС исключаем */
and    spd.ref_kodinsz = pa.fk_contract(+)
and    pa.fk_contract is null -- 9 соглашений нет!
