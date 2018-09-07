merge into pension_agreement_addendums paa
    using (select pa.fk_contract,
                  pa.effective_date,
                  pa.fk_debit,
                  case when pa.fk_scheme in (1, 5, 6) then import_assignments_pkg.get_sspv_id(pa.fk_scheme) end fk_sspv,
                  pa.pa_amount,
                  pa.creation_date
           from   pension_agreements_v pa
          ) u
    on    (paa.fk_pension_agreement = u.fk_contract and paa.serialno = 0)
    when not matched then
      insert(
        id,
        fk_pension_agreement,
        fk_base_doc,
        fk_provacct,
        serialno,
        canceled,
        amount,
        alt_date_begin,
        creation_date
      ) values (
        pension_agreement_addendum_seq.nextval,
        u.fk_contract,
        u.fk_contract,
        coalesce(u.fk_debit, u.fk_sspv),
        0,
        0,
        u.pa_amount,
        u.effective_date,
        u.creation_date --более ставить нечего при импорте...
      )
/
update (
      select paa.id, paa.canceled, paa.canceled_new
      from (
              select paa.id,
                     paa.fk_pension_agreement,
                     paa.serialno,
                     paa.canceled,
                     coalesce(
                       (select min(paa2.serialno)
                        from   pension_agreement_addendums paa2
                        where  1=1
                        and    paa2.serialno > paa.serialno
                        and    paa2.alt_date_begin <= paa.alt_date_begin
                        and    paa2.fk_pension_agreement = paa.fk_pension_agreement
                       ),
                       0
                     ) canceled_new,
                     paa.amount,
                     paa.alt_date_begin,
                     paa.alt_date_end,
                     paa.creation_date
              from   pension_agreement_addendums paa
              where  paa.fk_pension_agreement in (
                       select pa.fk_contract
                       from   pension_agreements_v pa
                     )
           ) paa
      where paa.canceled <> paa.canceled_new
    ) paa
    set paa.canceled = paa.canceled_new
/
