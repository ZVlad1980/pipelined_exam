select p.deathdate, pa.*
from   transform_contragents tc,
       contracts             bcn,
       pension_agreements    pa,
       contracts             cn,
       people                p
where  tc.ssylka_fl = 297214
and    bcn.fk_document = tc.fk_contract
and    pa.fk_base_contract = bcn.fk_document
and    cn.fk_document = pa.fk_contract
and    p.fk_contragent = cn.fk_contragent
/
select p.deathdate, pa.*
from   contracts             bcn,
       pension_agreements    pa,
       contracts             cn,
       people                p
where  1=1
and    cn.fk_document = pa.fk_contract
and    pa.fk_base_contract = bcn.fk_document
and    bcn.fk_contragent = p.fk_contragent
and    p.fk_contragent = 1252481
/
select tc.*, rowid
from   transform_contragents tc
where  tc.ssylka_fl = 5635
/
select *
from   contracts cn
where  cn.fk_contragent = 2931402
