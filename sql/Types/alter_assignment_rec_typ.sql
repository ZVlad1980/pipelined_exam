alter type assignment_rec_typ add attribute addendum_from_date date cascade;
alter type assignment_rec_typ add attribute last_pay_date      date cascade;
alter type assignment_rec_typ add attribute effective_date     date cascade;
alter type assignment_rec_typ add attribute expiration_date    date cascade;
alter type assignment_rec_typ add attribute account_balance    number cascade;
alter type assignment_rec_typ add attribute total_amount       number cascade;
alter type assignment_rec_typ add attribute pension_amount     number cascade;
alter type assignment_rec_typ add attribute is_ips             varchar2(1) cascade;
alter type assignment_rec_typ add attribute scheme_type        varchar2(10) cascade;
