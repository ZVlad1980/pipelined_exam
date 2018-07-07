create or replace trigger pension_agrmnt_adds_bi_trg
  before update
  on pension_agreement_addendums 
  referencing old as old new as new
  for each row
begin
  if not(nvl(:old.is_new, 'E') = 'Y' and :new.is_new is null) then
    :new.is_new := 'Y';
  end if;
end pension_agrmnt_adds_bi_trg;
/
