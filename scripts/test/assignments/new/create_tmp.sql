create table agreements_list_t(
  id                  int constraint agreements_list_pk primary key using index tablespace GFNDINDX,
  FK_CONTRACT         NUMBER(10,0) NOT NULL ENABLE constraint agreements_list_uk unique using index tablespace GFNDINDX,
  period_code         number(10) ,
  FK_DEBIT            NUMBER(10,0), 
  FK_CREDIT           NUMBER(10,0), 
  FK_SCHEME           NUMBER(10,0), 
  FK_CONTRAGENT       NUMBER(10,0), 
  EFFECTIVE_DATE      DATE, 
  LAST_PAY_DATE       DATE
);
/
create table pay_gfnpo_logs(
  start_id   number,
  end_id     number,
  created_at timestamp default systimestamp,
  rows_cnt   number,
  duration   number,
  session_id number
)
/
create table assignments_month_t(
paydate date
)
/
insert into assignments_month_t(
paydate 
)
select add_months(to_date(20160101, 'yyyymmdd'), level - 1) paydate
      from   dual
      connect by level < 36
