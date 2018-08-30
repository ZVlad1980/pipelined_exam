select count(1) from (
select op.action_date open_date, cl.action_date close_date, pa.effective_date, pa.expiration_date, pa.state, pa.isarhv,
       acc.*
from   transform_pa_accounts tac,
       pension_agreements    pa,
       accounts              acc,
       actions               op,
       actions               cl
where  1=1--tac.fk_account is not null
and    pa.fk_contract = tac.fk_contract
and    acc.id = tac.fk_account
and    op.id = acc.fk_opened
and    cl.id(+) = acc.fk_closed
)
/
select count(1)
from   transform_pa_accounts tac,
       accounts              acc
where  1=1--tac.fk_account is not null
and    acc.fk_doc_with_acct = tac.fk_contract
and    acc.fk_opened is not null
