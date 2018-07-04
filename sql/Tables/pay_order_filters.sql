create table pay_order_filters (
  id int
    default pay_order_filter_seq.nextval
    constraint pay_order_filters_pk primary key,
  fk_pay_order int not null,
  filter_code  varchar2(10)
    constraint pay_order_filter_code_chk 
      check (filter_code in ('COMPANY', 'CONTRACT')),
  filter_value int,
  constraint pay_order_filter_po_fk 
    foreign key (fk_pay_order)
    references pay_orders(fk_document)
)
/
create index pay_order_filter_po_ix on pay_order_filters(fk_pay_order)
/
