CREATE DATABASE LINK weekly_vbz
CONNECT TO gazfond IDENTIFIED BY gazfond
USING '(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))) (CONNECT_DATA = (SERVER=dedicated)(SERVICE_NAME=weekly_vbz)))'
/
truncate table pay_restrictions
/
insert into pay_restrictions
  select *
  from   pay_restrictions@weekly_vbz
/
CREATE DATABASE LINK weekly_vbz
CONNECT TO gazfond IDENTIFIED BY gazfond
USING '(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = 10.1.1.159)(PORT = 1521))) (CONNECT_DATA = (SERVER=dedicated)(SERVICE_NAME=weekly_vbz)))'
/
