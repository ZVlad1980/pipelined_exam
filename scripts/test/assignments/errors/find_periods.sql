with w_months as ( --список обрабатываемых месяцев
  select /*+ materialize*/
         m.month_date,
         last_day(m.month_date) end_month_date
  from   lateral(
              select add_months(to_date(19991201, 'yyyymmdd'), -1 * (level - 1)) month_date
              from   dual
              connect by level < 61 --:depth_months
         ) m
)
select m.month_date, pd.*
from   sp_pen_dog_v   pd,
       w_months       m
where  1=1
and    not exists (
         select 1
         from   sp_ogr_pv op
         where  op.kod_ogr_pv < 1000
         and    op.kod_ogr_pv <> 3
         and    op.ssylka_fl = pd.ssylka
         and    m.month_date between op.nach_deistv and coalesce(op.okon_deistv, m.month_date)
       )
and    not exists (
         select 1
         from   vypl_pen vp
         where  vp.ssylka_fl = pd.ssylka
         and    vp.data_nachisl between m.month_date and m.end_month_date
       )
and    m.month_date between pd.data_nach_vypl and coalesce(pd.data_okon_vypl, m.month_date)
and    pd.status_pen in ('и', 'п')
and    pd.data_nach_vypl < to_date(20000101, 'yyyymmdd')
