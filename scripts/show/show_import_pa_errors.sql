--ImportPA_20180720091207
select * from ERR$_IMP_DOCUMENTS where ORA_ERR_TAG$ = &l_err_tag;
select * from ERR$_IMP_CONTRACTS where ORA_ERR_TAG$ = &l_err_tag;
select * from ERR$_IMP_PENSION_AGREEMENTS where ORA_ERR_TAG$ = &l_err_tag;
select * from transform_pa tpa where tpa.fk_contract is null
