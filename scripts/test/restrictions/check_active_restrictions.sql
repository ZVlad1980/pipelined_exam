select count(1) --38507/31593 all/active
from   pension_agreements_charge_v pa
where  exists(
         select 1
         from   pay_restrictions pr
         where  pr.fk_doc_with_acct = pa.fk_contract
         and    pr.fk_document_cancel is null
       )
/
select count(1) --31729
from   fnd.sp_pen_dog pd,
       fnd.sp_lspv    lspv
where  1=1
and    exists(
         select 1
         from   fnd.sp_ogr_pv_v op
         where  op.ssylka_fl = pd.ssylka
         and    op.source_table = 'SP_OGR_PV'
       )
and    pd.shema_dog in (1,2,3,4,5,6,8)
and    pd.ssylka = lspv.ssylka_fl
and    lspv.status_pen in ('п','и')
/
select pd.ssylka, pa.*
from   fnd.sp_pen_dog pd,
       fnd.sp_lspv    lspv,
       transform_contragents tc,
       pension_agreements_v pa
where  1=1
and    not exists(
         select 1
         from   pay_restrictions pr
         where  pr.fk_doc_with_acct = pa.fk_contract
         and    pr.fk_document_cancel is null
       )
and    pa.state = 1 and pa.isarhv = 0
and    pa.effective_date = pd.data_nach_vypl
and    pa.fk_base_contract = tc.fk_contract
and    tc.ssylka_fl = pd.ssylka
and    exists(
         select 1
         from   fnd.sp_ogr_pv_rev_v op
         where  op.ssylka_fl = pd.ssylka
         and    op.source_table = 'SP_OGR_PV'
         and    op.nach_deistv < to_date(20500101, 'yyyymmdd')
       )
and    pd.shema_dog in (1,2,3,4,5,6,8)
and    pd.ssylka = lspv.ssylka_fl
and    lspv.status_pen in ('п','и')
