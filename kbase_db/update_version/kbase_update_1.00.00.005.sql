-->>
SET search_path = kbase, public, pg_catalog;
/*
-- ######## перевіряємо щоб БД була попередньої версії ############################
do $$
<<check_version>>
declare
	v_version_old varchar(50) := '1.00.00.004';
	v_version     varchar(50);
begin
	select s.value
		into v_version
		from settings s
		where s.alias = 'VERSION_DB_NUMBER'
	;
	if v_version_old <> v_version then
		--raise notice 'DB version too old, (% <> %)', v_version, v_version_old;
        RAISE EXCEPTION 'DB version mismatch: expected %, current %', v_version_old, v_version;
	end if;
end check_version $$;

-- ######## update table Settings for new version ############################
update settings
	set value = '1.00.00.005',
		descr = 'fix after review',
		date_modified = now(),
		user_modified = "current_user"()
where alias = 'VERSION_DB_NUMBER'
;
update settings
	set value = '25.07.2026',
		descr = '',
		date_modified = now(),
		user_modified = "current_user"()
where alias = 'VERSION_DB_END_DATE' 
;

--######## 
DROP INDEX IF EXISTS ind_settings_alias;

CREATE INDEX idx_section_document_info_block_type_components_type_id
  ON kbase.section_document_info_block_type_components (section_document_info_block_type_id);
*/


--<<
