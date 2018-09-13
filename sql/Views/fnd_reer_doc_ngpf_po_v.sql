create or replace view reer_doc_ngpf_po_v as
  select 1 flag_usage,
         row_number()over(partition by payment_period, half_month order by rd.den, rd.ssylka) rn, --номер PO в одном полупериоде
         max(rd.half_month)over(partition by payment_period) max_half_month,
         rd.ssylka         ssylka_doc,
         rd.ref_kodinsz    fk_document,
         rd.operation_date,
         rd.payment_period,
         rd.half_month,
         rd.tip_doc,
         rd.data_doc,
         rd.kem_podpis,
         rd.kr_soderg
  from   (
            select rd.ssylka,
                   rd.ref_kodinsz,
                   rd.den,
                   to_date(trim(to_char(rd.den, '00')) || ' ' || rd.mes || ' ' ||
                           to_char(rd.god),
                           'dd mon yyyy',
                           'NLS_DATE_LANGUAGE = Russian') operation_date,
                   to_date('01 ' || rd.mes || ' ' || to_char(rd.god),
                           'dd mon yyyy',
                           'NLS_DATE_LANGUAGE = Russian') payment_period,
                   case
                     when den < 15 or SSYLKA in (47, 164) then
                      1
                     else
                      2
                   end half_month,
                   1 flag_usage,
                   rd.tip_doc,
                   rd.data_doc,
                   rd.kem_podpis,
                   rd.kr_soderg
            from   (select rd.ssylka,
                           rd.tip_doc,
                           rd.data_doc,
                           rd.kem_podpis,
                           rd.kr_soderg,
                           rd.ref_kodinsz,
                           case
                             when rd.kr_soderg like '%первая%' or
                                  rd.kr_soderg like '%перв.пол%' then
                              10
                             when rd.kr_soderg like '%вторая%' or
                                  rd.kr_soderg like '%втор.пол%' then
                              25
                             else
                              nvl(extract(day from data_doc), 1)
                           end den,
                           nvl(substr(regexp_substr(rd.kr_soderg,
                                 '(январь|февраль|март|апрель|май|июнь|июль|август|сентябрь|октябрь|ноябрь|декабрь)'),
                                 1,
                                 3
                               ),
                               case rd.ssylka
                                 when 531 then
                                  'янв'
                                 when 414 then
                                  'дек'
                                 when 359 then
                                  'ноя'
                                 when 313 then
                                  'окт'
                                 when 173 then
                                  'сен'
                                 when 164 then
                                  'июл'
                                 when 103 then
                                  'авг'
                                 else
                                  to_char(rd.data_doc, 'mon', 'NLS_DATE_LANGUAGE = Russian')
                               end
                           )        mes,
                           nvl(to_number(substr(regexp_substr(rd.kr_soderg, '\D\d{4}(\D|$)'),
                                                2,
                                                4)),
                               case
                                 when rd.ssylka = 531 then
                                  1997
                                 else
                                  1996
                               end) god
                    from   reer_doc_ngpf rd
                    where  rd.kr_soderg like 'Закрыть%ИПС%'
                    and    rd.kr_soderg like '%выпл%пенс%'
                    and    rd.ssylka not in (48, 52, 71, 75)
                ) rd
          ) rd
 union all
  select 2 flag_usage,
         1 rn,
         1 max_half_month,
         rd.ssylka      ssylka_doc,
         rd.ref_kodinsz fk_document,
         rd.data_doc operation_date,
         trunc(rd.data_doc, 'MM') payment_period,
         1 half_month,
         rd.tip_doc,
         rd.data_doc,
         rd.kem_podpis,
         rd.kr_soderg
  from   fnd.reer_doc_ngpf rd
  where  rd.ssylka in (13906, 38132, 245849, 325969)
/
grant select on reer_doc_ngpf_po_v to gazfond
/
