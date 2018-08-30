select pa.fk_base_contract, count(1) cnt
from   pension_agreements pa,
       contracts          cn
where  cn.fk_document = pa.fk_base_contract
and    cn.fk_scheme in (1,2,3,4,5,6,8)
group by pa.fk_base_contract
having count(distinct pa.fk_contract) > 1
/*
2593140 2
6873030 2
1704259 2
12080980  2
2592430 2
2749431 2
6878896 2
11516856  2
2749459 2
3167812 2
5035203 2
10270118  2

*/
