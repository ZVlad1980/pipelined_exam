select vp.data_op           date_op
from   fnd.vypl_pen_v vp
where  vp.data_op between to_date(19960101, 'yyyymmdd') and to_date(19961231, 'yyyymmdd') --to_date(20180101, 'yyyymmdd') and to_date(20180331, 'yyyymmdd') --to_date(19960101, 'yyyymmdd') and to_date(19961231, 'yyyymmdd')
group by vp.data_op
order by vp.data_op
/

insert all
      when doc_exists = 'N' and ref_kodinsz is not null then
        insert into documents(id, doc_date, title, is_accounting_doc)
        document_seq.nextval,
        date_op,
        'Импорт начислений FND, ' || to_char(date_op, 'dd.mm.yyyy')
        0
        )
        values(ref_kodinsz, 2, cntr_date, doctitle, ref_kodinsz)
