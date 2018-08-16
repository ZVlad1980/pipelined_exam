
update sp_pen_dog_arh pda
set    pda.shema_dog = coalesce(
         (select pd.shema_dog from sp_pen_dog pd where pd.ssylka = pda.ssylka),
         (select tc.fk_scheme from gazfond.transform_contragents tc where tc.ssylka_fl = pda.ssylka)
       )
where  pda.shema_dog is null
/
commit
/
