-->>
SET search_path = kbase, public, pg_catalog;

-- ######## перевіряємо щоб БД була попередньої версії ############################
do $$
<<check_version>>
declare
	v_version_old varchar(50) := '1.00.00.005';
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
	set value = '1.00.00.006',
		descr = 'roles and groups',
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






--<<
