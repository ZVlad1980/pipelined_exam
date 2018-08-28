Drop table TRANSFORM_PAYORDERS_LNK;
--Drop table TRANSFORM_PAYORDERS_NPO;

Create table TRANSFORM_PAYORDERS_NPO as
Select q.*
       , to_date( trim(to_char(DEN,'00'))||' '||MES||' '||to_char(GOD),'dd mon yyyy', 'NLS_DATE_LANGUAGE = Russian') OPERATION_DATE 
       , to_date( '01 '||MES||' '||to_char(GOD),'dd mon yyyy', 'NLS_DATE_LANGUAGE = Russian') PAYMENT_PERIOD
       , case when DEN<15 then 1 else 2 end POLOVINA, 1 FLAG_USAGE
from (
Select SSYLKA, TIP_DOC, DATA_DOC, KEM_PODPIS, KR_SODERG, REF_KODINSZ 
       , case when KR_SODERG like '%первая%' or KR_SODERG like '%перв.пол%' then 10
              when KR_SODERG like '%вторая%' or KR_SODERG like '%втор.пол%' then 25
              else nvl(extract(DAY from DATA_DOC),1) 
         end DEN
       , nvl(
          substr(regexp_substr(KR_SODERG,'(январь|февраль|март|апрель|май|июнь|июль|август|сентябрь|октябрь|ноябрь|декабрь)'),1,3),
          case SSYLKA
            when 531 then 'янв'
            when 414 then 'дек'
            when 359 then 'ноя'
            when 313 then 'окт'
            when 173 then 'сен'            
            when 164 then 'июл'
            when 103 then 'авг'
            else to_char(DATA_DOC,'mon', 'NLS_DATE_LANGUAGE = Russian')
          end 
         )MES
       , nvl(to_number(substr(regexp_substr(KR_SODERG,'\D\d{4}(\D|$)'),2,4)), 
          case when SSYLKA=531 then 1997 else 1996 end
         ) GOD
from fnd.REER_DOC_NGPF 
   where KR_SODERG like 'Закрыть%ИПС%' and KR_SODERG like '%выпл%пенс%' and SSYLKA not in (48, 52, 71, 75)
) q
order by OPERATION_DATE;

Insert into TRANSFORM_PAYORDERS_NPO ( 
   SSYLKA, TIP_DOC, DATA_DOC, 
   KEM_PODPIS, KR_SODERG, REF_KODINSZ, 
   DEN, MES, GOD, 
   OPERATION_DATE, PAYMENT_PERIOD,
   POLOVINA, FLAG_USAGE
)
Select SSYLKA, TIP_DOC, DATA_DOC, KEM_PODPIS, KR_SODERG, REF_KODINSZ,
       extract(DAY from DATA_DOC) DEN, extract(MONTH from DATA_DOC) MES, extract(YEAR from DATA_DOC) GOD, 
       DATA_DOC OPERATION_DATE, trunc(DATA_DOC,'MON') PAYMENT_PERIOD, 1 POLOVINA, 2 FLAG_USAGE  
from fnd.REER_DOC_NGPF where SSYLKA in (13906,38132,245849,325969);

Commit;

ALTER TABLE TRANSFORM_PAYORDERS_NPO ADD (
  CONSTRAINT TRANSFORM_PAYORDERS_NPO_PK
  PRIMARY KEY
  (SSYLKA));
  
CREATE UNIQUE INDEX TRANSFORM_PAYORDERS_NPO_UI ON TRANSFORM_PAYORDERS_NPO
(REF_KODINSZ);  

Update TRANSFORM_PAYORDERS_NPO
set POLOVINA=1
where SSYLKA in (47,164);

Commit;

Update TRANSFORM_PAYORDERS_NPO
set  FLAG_USAGE = 3
where SSYLKA in (        
    Select SSYLKA from (
        Select hpo.* --SSYLKA
               , count(*) over (partition by PAYMENT_PERIOD, POLOVINA order by DEN, SSYLKA rows unbounded preceding) NN
        from TRANSFORM_PAYORDERS_NPO hpo
        where FLAG_USAGE=1
    ) where NN>1
);   

Commit;

Create table TRANSFORM_PAYORDERS_LNK as 
-- 4 исключения/это не распоряжение, а док-сон для операций списком: имитация выплаты пенсии в наследство и перерасчеты НДФЛ 
Select hpo.SSYLKA ORDER_FNDSSYLKA, hpo.REF_KODINSZ ORDER_GFDOCID, hpo.SSYLKA POCARD_FNDSSYLKA, hpo.REF_KODINSZ POCARD_GFDOCID
from (
    Select distinct SSYLKA_DOC
        from fnd.VYPL_PEN 
        where SSYLKA_DOC in (Select SSYLKA from TRANSFORM_PAYORDERS_NPO where FLAG_USAGE=2)
    ) poc
    inner join TRANSFORM_PAYORDERS_NPO hpo on hpo.SSYLKA=poc.SSYLKA_DOC;
    
ALTER TABLE TRANSFORM_PAYORDERS_LNK ADD (
  CONSTRAINT TRANSFORM_PAYORDERS_LNK_PK
  PRIMARY KEY
  (POCARD_FNDSSYLKA));
   
-- до апреля 98 года одна выплата в месяц
Insert into TRANSFORM_PAYORDERS_LNK(
       ORDER_FNDSSYLKA, ORDER_GFDOCID,   POCARD_FNDSSYLKA, POCARD_GFDOCID
)
Select hpo.SSYLKA,      hpo.REF_KODINSZ, rd.SSYLKA,        rd.REF_KODINSZ
from (
    Select distinct SSYLKA_DOC, DATA_OP 
        from fnd.VYPL_PEN 
        where NOM_VKL<>1001 and DATA_OP<to_date('01.04.1998','dd.mm.yyyy')
          and SSYLKA_DOC not in (Select SSYLKA from TRANSFORM_PAYORDERS_NPO where FLAG_USAGE=2)
    ) poc       
    inner join fnd.REER_DOC_NGPF rd on rd.SSYLKA=poc.SSYLKA_DOC  -- 3.866
    left join TRANSFORM_PAYORDERS_NPO hpo on hpo.PAYMENT_PERIOD=trunc(poc.DATA_OP,'MON') and FLAG_USAGE=1 and POLOVINA=1    
order by rd.SSYLKA, hpo.SSYLKA;     

Commit;   

-- с апреля 98 года две выплаты в месяц
Insert into TRANSFORM_PAYORDERS_LNK(
       ORDER_FNDSSYLKA, ORDER_GFDOCID, POCARD_FNDSSYLKA, POCARD_GFDOCID
)
Select hpo.SSYLKA PO_FND, hpo.REF_KODINSZ PO_GF, rd.SSYLKA POC_FND, rd.REF_KODINSZ POC_GF
from (
    Select distinct SSYLKA_DOC, DATA_OP, case when extract(DAY from DATA_OP)>15 then 2 else 1 end POLOVINA 
        from fnd.VYPL_PEN 
        where NOM_VKL<>1001 and DATA_OP>=to_date('01.04.1998','dd.mm.yyyy')
          and SSYLKA_DOC not in (Select SSYLKA from TRANSFORM_PAYORDERS_NPO where FLAG_USAGE=2)   
    ) poc       
    inner join fnd.REER_DOC_NGPF rd on rd.SSYLKA=poc.SSYLKA_DOC  -- 3.866
    inner join TRANSFORM_PAYORDERS_NPO hpo on hpo.PAYMENT_PERIOD=trunc(poc.DATA_OP,'MON') and hpo.POLOVINA=poc.POLOVINA and hpo.FLAG_USAGE=1
order by rd.SSYLKA, hpo.SSYLKA;     

Commit; 
    
-- как всегда не без исключений
--    01/12/1998  одно распоряжение за месяц, вторую половину платить по одному ордеру с первой 
Insert into TRANSFORM_PAYORDERS_LNK(
       ORDER_FNDSSYLKA, ORDER_GFDOCID, POCARD_FNDSSYLKA, POCARD_GFDOCID
)
Select hpo.SSYLKA PO_FND, hpo.REF_KODINSZ PO_GF, rd.SSYLKA POC_FND, rd.REF_KODINSZ POC_GF
from (
    Select distinct SSYLKA_DOC, DATA_OP 
        from fnd.VYPL_PEN 
        where NOM_VKL<>1001 and trunc(DATA_OP,'MON')=to_date('01.12.1998','dd.mm.yyyy')
          and extract(DAY from DATA_OP)>15 
          and SSYLKA_DOC not in (Select SSYLKA from TRANSFORM_PAYORDERS_NPO where FLAG_USAGE=2)    
    ) poc       
    inner join fnd.REER_DOC_NGPF rd on rd.SSYLKA=poc.SSYLKA_DOC  
    inner join TRANSFORM_PAYORDERS_NPO hpo on hpo.PAYMENT_PERIOD=trunc(poc.DATA_OP,'MON') and hpo.SSYLKA=6313
order by rd.SSYLKA, hpo.SSYLKA;     

Commit;

--    01/07/2009    одно распоряжение за месяц, вторую половину платить по одному ордеру с первой  
Insert into TRANSFORM_PAYORDERS_LNK(
       ORDER_FNDSSYLKA, ORDER_GFDOCID, POCARD_FNDSSYLKA, POCARD_GFDOCID
)
Select hpo.SSYLKA PO_FND, hpo.REF_KODINSZ PO_GF, rd.SSYLKA POC_FND, rd.REF_KODINSZ POC_GF
from (
    Select distinct SSYLKA_DOC, DATA_OP 
        from fnd.VYPL_PEN 
        where NOM_VKL<>1001 and trunc(DATA_OP,'MON')=to_date('01.01.2000','dd.mm.yyyy')
          and extract(DAY from DATA_OP)>15 
          and SSYLKA_DOC not in (Select SSYLKA from TRANSFORM_PAYORDERS_NPO where FLAG_USAGE=2)    
    ) poc       
    inner join fnd.REER_DOC_NGPF rd on rd.SSYLKA=poc.SSYLKA_DOC  
    inner join TRANSFORM_PAYORDERS_NPO hpo on hpo.PAYMENT_PERIOD=trunc(poc.DATA_OP,'MON') and hpo.SSYLKA=9588
order by rd.SSYLKA, hpo.SSYLKA;     

Commit;

--    01/07/2009    одно распоряжение за месяц, вторую половину платить по одному ордеру с первой  
Insert into TRANSFORM_PAYORDERS_LNK(
       ORDER_FNDSSYLKA, ORDER_GFDOCID, POCARD_FNDSSYLKA, POCARD_GFDOCID
)
Select hpo.SSYLKA PO_FND, hpo.REF_KODINSZ PO_GF, rd.SSYLKA POC_FND, rd.REF_KODINSZ POC_GF
from (
    Select distinct SSYLKA_DOC, DATA_OP 
        from fnd.VYPL_PEN 
        where NOM_VKL<>1001 and trunc(DATA_OP,'MON')=to_date('01.07.2009','dd.mm.yyyy')
          and extract(DAY from DATA_OP)>15 
          and SSYLKA_DOC not in (Select SSYLKA from TRANSFORM_PAYORDERS_NPO where FLAG_USAGE=2)    
    ) poc       
    inner join fnd.REER_DOC_NGPF rd on rd.SSYLKA=poc.SSYLKA_DOC  
    inner join TRANSFORM_PAYORDERS_NPO hpo on hpo.PAYMENT_PERIOD=trunc(poc.DATA_OP,'MON') and hpo.SSYLKA=161754
order by rd.SSYLKA, hpo.SSYLKA;     

Commit; 

--    Table dropped.
--    Table dropped.
--    Table created.
--    4 rows created.
--    Commit complete.
--    Table altered.
--    Index created.
--    2 rows updated.
--    Commit complete.
--    10 rows updated.
--    Commit complete.
--    Table created.
--    Table altered.
--    3487 rows created.
--    Commit complete.
--    97784 rows created.
--    Commit complete.
--    1 row created.
--    Commit complete.
--    18 rows created.
--    Commit complete.
--    6 rows created.
--    Commit complete.

/*
-- ПРОВЕРКА

    Select distinct SSYLKA_DOC from fnd.VYPL_PEN where NOM_VKL<>1001 and DATA_OP is not Null  -- 101.300
   MINUS
    Select POCARD_FNDSSYLKA from TRANSFORM_PAYORDERS_LNK;    -- 101.300
   -- нет записей 

*/     
