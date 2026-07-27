-->>
SET search_path = kbase, public, pg_catalog;
/*
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
		user_id_modified = 1
where alias = 'VERSION_DB_NUMBER'
;
update settings
	set value = '25.07.2026',
		descr = '',
		date_modified = now(),
		user_id_modified = 1
where alias = 'VERSION_DB_END_DATE' 
;

--######## 
ALTER TABLE kbase.sections DROP COLUMN IF EXISTS show_level;

--######## create tables ####################################
-- Create sequences
CREATE SEQUENCE IF NOT EXISTS seq_groups;
CREATE SEQUENCE IF NOT EXISTS seq_user_groups;
CREATE SEQUENCE IF NOT EXISTS seq_section_group_access;

-- Create groups table
CREATE TABLE groups (
    id              BIGINT PRIMARY KEY DEFAULT nextval('seq_groups'),
    name            VARCHAR NOT NULL,
    descr           VARCHAR,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    date_created    TIMESTAMPTZ NOT NULL DEFAULT now(),
    date_modified   TIMESTAMPTZ NOT NULL DEFAULT now(),
    user_id_created BIGINT NOT NULL REFERENCES users(id),
    user_id_modified BIGINT NOT NULL REFERENCES users(id)
);

-- Create user_groups table
CREATE TABLE user_groups (
    id              BIGINT PRIMARY KEY DEFAULT nextval('seq_user_groups'),
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    group_id        BIGINT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    descr           VARCHAR,
    date_created    TIMESTAMPTZ NOT NULL DEFAULT now(),
    date_modified   TIMESTAMPTZ NOT NULL DEFAULT now(),
    user_id_created BIGINT NOT NULL REFERENCES users(id),
    user_id_modified BIGINT NOT NULL REFERENCES users(id),
    UNIQUE(user_id, group_id)
);

-- Create section_group_access table
CREATE TABLE section_group_access (
    section_id      BIGINT NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    group_id        BIGINT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    access_level    SMALLINT NOT NULL DEFAULT 1,
    is_inherited    BOOLEAN NOT NULL DEFAULT false,
    date_created    TIMESTAMPTZ NOT NULL DEFAULT now(),
    date_modified   TIMESTAMPTZ NOT NULL DEFAULT now(),
    user_id_created BIGINT NOT NULL REFERENCES users(id),
    user_id_modified BIGINT NOT NULL REFERENCES users(id),
    PRIMARY KEY (section_id, group_id),
    CONSTRAINT chk_section_group_access_level CHECK (access_level IN (1, 2))
);

-- Comment on access_level
COMMENT ON COLUMN section_group_access.access_level IS 'Access level: 1 = view, 2 = edit';

-- Create indexes for performance
CREATE INDEX idx_user_groups_user_id ON user_groups(user_id);
CREATE INDEX idx_user_groups_group_id ON user_groups(group_id);
CREATE INDEX idx_section_group_access_section_id ON section_group_access(section_id);
CREATE INDEX idx_section_group_access_group_id ON section_group_access(group_id);

-- Grant permissions to role kbase
GRANT ALL ON groups TO kbase;
GRANT ALL ON user_groups TO kbase;
GRANT ALL ON section_group_access TO kbase;
GRANT USAGE, SELECT ON SEQUENCE seq_groups TO kbase;
GRANT USAGE, SELECT ON SEQUENCE seq_user_groups TO kbase;
GRANT USAGE, SELECT ON SEQUENCE seq_section_group_access TO kbase;
*/
--######## 

--<<
