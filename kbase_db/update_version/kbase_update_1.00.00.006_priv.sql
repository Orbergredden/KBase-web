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

--######## role_privileges ##############################################
-- Add date/user columns with constraints (matching roles table pattern)
ALTER TABLE kbase.role_privileges
    ADD COLUMN date_created TIMESTAMPTZ DEFAULT now(),
    ADD COLUMN date_modified TIMESTAMPTZ DEFAULT now(),
    ADD COLUMN user_id_created BIGINT DEFAULT 1,
    ADD COLUMN user_id_modified BIGINT DEFAULT 1;

-- Add FK constraints for user_id_created/modified
ALTER TABLE kbase.role_privileges
    ADD CONSTRAINT fk_role_privileges_user_id_created 
        FOREIGN KEY (user_id_created) REFERENCES kbase.users(id),
    ADD CONSTRAINT fk_role_privileges_user_id_modified 
        FOREIGN KEY (user_id_modified) REFERENCES kbase.users(id);

-- Delete all records
TRUNCATE TABLE kbase.role_privileges RESTART IDENTITY CASCADE;

--######## kbase.privileges #####################################
-- Delete all existing privileges and reset sequence
TRUNCATE TABLE kbase.privileges RESTART IDENTITY CASCADE;

-- Insert new privileges
INSERT INTO kbase.privileges (name, descr, user_id_created, user_id_modified) VALUES
    ('admin',           'Full access: edit users, roles, privileges, global settings', 1, 1),
    ('admin-view',      'View users, roles, privileges, global settings', 1, 1),
    ('icons-edit',      'Edit icons', 1, 1),
    ('icons-view',      'View icons', 1, 1),
    ('logs-view',       'View logs', 1, 1),
    ('sections-full',   'Full access to all sections', 1, 1),
    ('sections-edit',   'Edit sections', 1, 1),
    ('sections-view',   'View sections', 1, 1),
    ('section_categories-edit',       'Edit section categories', 1, 1),
    ('section_categories-view',       'View section categories', 1, 1),
    ('section_document_info_block_styles-edit', 'Edit document info block styles', 1, 1),
    ('section_document_info_block_styles-view', 'View document info block styles', 1, 1),
    ('templates-edit',  'Edit templates', 1, 1),
    ('templates-view',  'View templates', 1, 1);

--########  ###############################################
-- 1. Add groups
INSERT INTO kbase.groups (name, descr, is_active, user_id_created, user_id_modified) VALUES
    ('Адміністратори',  'Full system access',                true, 1, 1),
    ('Розробники',      'Developers with edit access',       true, 1, 1),
    ('Тестери',         'Testers with view/edit access',     true, 1, 1),
    ('Супровід',        'Support team with view/edit access',true, 1, 1),
    ('Менеджери',       'Managers with view access',         true, 1, 1),
    ('Бухгалтери',      'Accountants with limited access',   true, 1, 1);

-- 2. Assign admin user (id=1) to "Адміністратори" group
INSERT INTO kbase.user_groups (user_id, group_id, descr, user_id_created, user_id_modified)
SELECT 1, g.id, 'Admin group assignment', 1, 1
FROM kbase.groups g
WHERE g.name = 'Адміністратори';

-- 3. Assign privileges to ROLE_ADMIN (id=1)
INSERT INTO kbase.role_privileges (role_id, privilege_id)
SELECT 1, p.id
FROM kbase.privileges p
WHERE p.name IN (
    'admin',
    'icons-edit',
    'logs-view',
    'sections-full',
    'section_categories-edit',
    'section_document_info_block_styles-edit',
    'templates-edit'
);
--<<
