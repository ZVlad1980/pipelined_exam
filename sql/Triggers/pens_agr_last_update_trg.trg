create or replace trigger pens_agr_last_update_trg
  before insert or update on pension_agreements
  referencing new as new old as old
  for each row
declare

  procedure add_addendums_ is
  begin
    null;/*insert into pension_agreement_addendums(
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
      :new.fk_contract,
      :new.fk_contract,
      null,
      0,
      0,
      :new.amount,
      :new.effective_date,
      sysdate
    ); --*/
  exception
    when others then
      /*
      TODO: owner="v.zhuravov" created="14.08.2018"
      text="Добавить запись в лог"
      */
      null;
  end add_addendums_;
  
  procedure update_addendums_ is
  begin
    null;/*update pension_agreement_addendums paa
    set    paa.alt_date_begin = :new.effective_date,
           paa.amount         = :new.amount
    where  paa.fk_pension_agreement = :new.fk_contract; --*/
  exception
    when others then
      /*
      TODO: owner="v.zhuravov" created="14.08.2018"
      text="Добавить запись в лог"
      */
      null;
  end update_addendums_;
  
begin
  :new.last_update := sysdate;
  /*if inserting or :new.fk_contract <> :old.fk_contract then
    add_addendums_;
  elsif :new.effective_date <> :old.effective_date or :new.amount <> :old.amount then
    update_addendums_;
  end if;*/
    
end;
/
