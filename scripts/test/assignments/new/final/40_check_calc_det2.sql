select *
from   pension_agreements_v pa
where  pa.fk_contract in (
  11871949,
12034653,
11980113,
12034703,
12034780,
12135916,
12058806,
12058455,
12058991,
12059123,
12058940,
12093545,
12070920,
12100497,
12100626,
12068711,
12052949,
12082862,
12076935,
12079681,
12080460,
12058870,
12059100
)
= &fk_pa --2763033
/
select *
from   fnd.sp_pen_dog_v pd
where  pd.ssylka = &ssylka
/
select *
from   fnd.sp_izm_pd_v pd
where  pd.ssylka_fl = &ssylka
/
select *
from   pay_restrictions pr
where  pr.fk_doc_with_acct = &fk_pa
/
select pap.*, pap.rowid
from   pension_agreement_periods pap
where  pap.fk_pension_agreement = &fk_pa
/
select *
from   assignments asg
where  asg.fk_doc_with_acct = &fk_pa
and    asg.fk_asgmt_type = 2
order by asg.paydate desc
/
select *
from   pension_agreement_addendums paa
where  paa.fk_pension_agreement = &fk_pa
