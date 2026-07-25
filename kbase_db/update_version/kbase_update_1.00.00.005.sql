-->>
SET search_path = kbase, public, pg_catalog;

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

CREATE INDEX idx_sections_user_id_created ON sections (user_id_created);
CREATE INDEX idx_sections_user_id_modified ON sections (user_id_modified);

CREATE INDEX idx_refresh_tokens_expiry_date ON refresh_tokens (expiry_date);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens (user_id);

ALTER TABLE section_types ALTER COLUMN name SET NOT NULL;
ALTER TABLE sections ALTER COLUMN name SET NOT NULL;

DROP INDEX IF EXISTS idx_section_document_info_block_headers_position;

ALTER TABLE users 
DROP CONSTRAINT fk_users_role,
ADD CONSTRAINT fk_users_role 
    FOREIGN KEY (role_id) 
    REFERENCES roles (id) 
    ON UPDATE NO ACTION 
    ON DELETE RESTRICT;

--######## field user ##############################################
-- Add new bigint columns with default to admin user (id=1)
ALTER TABLE kbase.privileges 
  ADD COLUMN user_id_created BIGINT DEFAULT 1,
  ADD COLUMN user_id_modified BIGINT DEFAULT 1;

ALTER TABLE kbase.roles 
  ADD COLUMN user_id_created BIGINT DEFAULT 1,
  ADD COLUMN user_id_modified BIGINT DEFAULT 1;

ALTER TABLE kbase.section_types 
  ADD COLUMN user_id_created BIGINT DEFAULT 1,
  ADD COLUMN user_id_modified BIGINT DEFAULT 1;

ALTER TABLE kbase.settings 
  ADD COLUMN user_id_created BIGINT DEFAULT 1,
  ADD COLUMN user_id_modified BIGINT DEFAULT 1;

ALTER TABLE kbase.users 
  ADD COLUMN user_id_created BIGINT DEFAULT 1,
  ADD COLUMN user_id_modified BIGINT DEFAULT 1;

-- Update with username->id mapping (adjust mapping as needed)
UPDATE kbase.privileges 
SET user_id_created = CASE user_created WHEN 'postgres' THEN 1 WHEN 'kbase_admin' THEN 1 ELSE 1 END,
    user_id_modified = CASE user_modified WHEN 'postgres' THEN 1 WHEN 'kbase_admin' THEN 1 ELSE 1 END;

UPDATE kbase.roles 
SET user_id_created = CASE user_created WHEN 'postgres' THEN 1 WHEN 'kbase_admin' THEN 1 ELSE 1 END,
    user_id_modified = CASE user_modified WHEN 'postgres' THEN 1 WHEN 'kbase_admin' THEN 1 ELSE 1 END;

UPDATE kbase.section_types 
SET user_id_created = CASE user_created WHEN 'postgres' THEN 1 WHEN 'kbase_admin' THEN 1 ELSE 1 END,
    user_id_modified = CASE user_modified WHEN 'postgres' THEN 1 WHEN 'kbase_admin' THEN 1 ELSE 1 END;

UPDATE kbase.settings 
SET user_id_created = CASE user_created WHEN 'postgres' THEN 1 WHEN 'kbase_admin' THEN 1 ELSE 1 END,
    user_id_modified = CASE user_modified WHEN 'postgres' THEN 1 WHEN 'kbase_admin' THEN 1 ELSE 1 END;

UPDATE kbase.users 
SET user_id_created = CASE user_created WHEN 'postgres' THEN 1 WHEN 'kbase_admin' THEN 1 ELSE 1 END,
    user_id_modified = CASE user_modified WHEN 'postgres' THEN 1 WHEN 'kbase_admin' THEN 1 ELSE 1 END;

-- Drop old columns
ALTER TABLE kbase.privileges DROP COLUMN user_created, DROP COLUMN user_modified;
ALTER TABLE kbase.roles DROP COLUMN user_created, DROP COLUMN user_modified;
ALTER TABLE kbase.section_types DROP COLUMN user_created, DROP COLUMN user_modified;
ALTER TABLE kbase.settings DROP COLUMN user_created, DROP COLUMN user_modified;
ALTER TABLE kbase.users DROP COLUMN user_created, DROP COLUMN user_modified;

-- Add foreign keys (matching pattern from other tables)
ALTER TABLE kbase.privileges 
  ADD CONSTRAINT fk_privileges_user_id_created FOREIGN KEY (user_id_created) REFERENCES kbase.users(id),
  ADD CONSTRAINT fk_privileges_user_id_modified FOREIGN KEY (user_id_modified) REFERENCES kbase.users(id);

ALTER TABLE kbase.roles 
  ADD CONSTRAINT fk_roles_user_id_created FOREIGN KEY (user_id_created) REFERENCES kbase.users(id),
  ADD CONSTRAINT fk_roles_user_id_modified FOREIGN KEY (user_id_modified) REFERENCES kbase.users(id);

ALTER TABLE kbase.section_types 
  ADD CONSTRAINT fk_section_types_user_id_created FOREIGN KEY (user_id_created) REFERENCES kbase.users(id),
  ADD CONSTRAINT fk_section_types_user_id_modified FOREIGN KEY (user_id_modified) REFERENCES kbase.users(id);

ALTER TABLE kbase.settings 
  ADD CONSTRAINT fk_settings_user_id_created FOREIGN KEY (user_id_created) REFERENCES kbase.users(id),
  ADD CONSTRAINT fk_settings_user_id_modified FOREIGN KEY (user_id_modified) REFERENCES kbase.users(id);

ALTER TABLE kbase.users 
  ADD CONSTRAINT fk_users_user_id_created FOREIGN KEY (user_id_created) REFERENCES kbase.users(id),
  ADD CONSTRAINT fk_users_user_id_modified FOREIGN KEY (user_id_modified) REFERENCES kbase.users(id);

--######## add time zone ############################################
-- icons
ALTER TABLE kbase.icons
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- logs
ALTER TABLE kbase.logs
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC';

-- privileges
ALTER TABLE kbase.privileges
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- refresh_tokens
ALTER TABLE kbase.refresh_tokens
  ALTER COLUMN expiry_date TYPE timestamptz USING expiry_date AT TIME ZONE 'UTC';

-- roles
ALTER TABLE kbase.roles
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- section_categories
ALTER TABLE kbase.section_categories
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- section_dictionaries
ALTER TABLE kbase.section_dictionaries
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- section_document_info_block_components_binary
ALTER TABLE kbase.section_document_info_block_components_binary
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- section_document_info_block_components_number
ALTER TABLE kbase.section_document_info_block_components_number
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- section_document_info_block_components_text
ALTER TABLE kbase.section_document_info_block_components_text
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- section_document_info_block_headers
ALTER TABLE kbase.section_document_info_block_headers
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- section_document_info_block_styles
ALTER TABLE kbase.section_document_info_block_styles
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- section_document_info_block_type
ALTER TABLE kbase.section_document_info_block_type
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- section_document_info_block_type_components
ALTER TABLE kbase.section_document_info_block_type_components
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- section_documents
ALTER TABLE kbase.section_documents
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- section_types
ALTER TABLE kbase.section_types
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- sections
ALTER TABLE kbase.sections
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified_info TYPE timestamptz USING date_modified_info AT TIME ZONE 'UTC';

-- settings
ALTER TABLE kbase.settings
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- template_bodies
ALTER TABLE kbase.template_bodies
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- template_color_themes
ALTER TABLE kbase.template_color_themes
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- template_files
ALTER TABLE kbase.template_files
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- templates
ALTER TABLE kbase.templates
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

-- users
ALTER TABLE kbase.users
  ALTER COLUMN date_created TYPE timestamptz USING date_created AT TIME ZONE 'UTC',
  ALTER COLUMN date_modified TYPE timestamptz USING date_modified AT TIME ZONE 'UTC';

--######## log_types #####################################################
-- Create log_types reference table (matching pattern of other reference tables like section_types, roles, etc.)
CREATE TABLE log_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200),
    date_created TIMESTAMPTZ NOT NULL DEFAULT now(),
    date_modified TIMESTAMPTZ NOT NULL DEFAULT now(),
    user_id_created BIGINT NOT NULL REFERENCES kbase.users(id),
    user_id_modified BIGINT NOT NULL REFERENCES kbase.users(id)
);

-- Insert standard log types
INSERT INTO kbase.log_types (name, description, user_id_created, user_id_modified) VALUES
    ('info', 'Informational messages', 1, 1),
    ('warning', 'Warning messages', 1, 1),
    ('error', 'Error messages', 1, 1),
    ('debug', 'Debug messages', 1, 1),
    ('audit', 'Audit trail entries', 1, 1);

-- Add foreign key column to logs
ALTER TABLE kbase.logs ADD COLUMN log_type_id BIGINT REFERENCES kbase.log_types(id);

-- Drop old varchar column (after data migration)
ALTER TABLE logs DROP COLUMN log_type;
--<<
