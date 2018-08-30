select pa.cnt,
       pa.fk_base_contract,
       pa.fk_contract,
       pa.effective_date,
       pa.min_serialno,
       pa.max_serialno,
       pa.next_min_serialno,
       pa.prev_max_serialno,
       pa.min_alt_date_begin,
       pa.max_alt_date_end
from   (
select pa.cnt,
       pa.fk_base_contract,
       pa.fk_contract,
       pa.effective_date,
       pa.min_serialno,
       pa.max_serialno,
       lead(min_serialno)over(partition by pa.fk_base_contract order by pa.fk_base_contract,pa.effective_date) next_min_serialno,
       lag(max_serialno)over(partition by pa.fk_base_contract order by pa.fk_base_contract,pa.effective_date) prev_max_serialno,
       pa.min_alt_date_begin,
       pa.max_alt_date_end
from   (
select /*+ first_rows(50)*/
       pa.cnt,
       pa.fk_base_contract,
       pa.fk_contract,
       pa.effective_date,
       min(paa.serialno) min_serialno,
       max(paa.serialno) max_serialno,
       min(paa.alt_date_begin) min_alt_date_begin,
       max(paa.alt_date_end)   max_alt_date_end
from   pension_agreements_imp_v pa,
       pension_agreement_addendums paa
where  1=1
and    paa.serialno <> 0
and    paa.fk_pension_agreement = pa.fk_contract
and    pa.cnt > 1
group by pa.cnt, pa.fk_base_contract, pa.fk_contract, pa.effective_date
) pa )pa where 
pa.min_serialno < pa.prev_max_serialno
or
       pa.max_serialno > pa.next_min_serialno
order by pa.fk_base_contract,
       pa.effective_date
/
select *
from   pension_agreements          pa,
       pension_agreement_addendums paa
where  1=1
and    paa.fk_pension_agreement = pa.fk_contract
and    pa.fk_base_contract = 2389723
)pa
order by pa.fk_base_contract,
       pa.effective_date, paa.serialno
