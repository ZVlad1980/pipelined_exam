select pa.*
from   pension_agreements_v pa,
       fnd.sp_pen_dog_v     pd
where  pa.state = 1
and    pd.ref_kodinsz(+) = pa.fk_contract
and    pd.source_table(+) = 'SP_PEN_DOG'
and    pd.status_pen(+) in ('п' , 'и')
and    pd.nom_vkl is null
/
select count(1) --170212 --170201
from   pension_agreements pa,
       fnd.sp_pen_dog_v   pd
where  pa.state = 1
and    pd.ref_kodinsz = pa.fk_contract
and    pd.source_table = 'SP_PEN_DOG'
/
select count(1) --168217
from   fnd.sp_pen_dog_v   pd,
       pension_agreements pa
where  1=1
and    pa.fk_contract = pd.ref_kodinsz
and    pd.source_table = 'SP_PEN_DOG'
and    pd.status_pen in ('п' , 'и')
