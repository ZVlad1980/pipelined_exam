select cn.*--amount, pa.effective_date, cn.cntr_date, pd.*
from   pension_agreements pa,
       contracts          cn,
       pay_decisions      pd
where  1=1
--and    pd.id is null
and    pd.fk_contract = pa.fk_base_contract
and    cn.fk_scheme <> 7
and    cn.fk_cntr_type = 6
and    cn.fk_document = pa.fk_contract
and    pa.fk_base_contract = 2890169
