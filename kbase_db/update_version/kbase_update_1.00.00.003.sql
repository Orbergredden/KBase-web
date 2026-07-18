-->>
SET search_path = kbase, public, pg_catalog;
/*
-- ######## перевіряємо щоб БД була попередньої версії ############################
do $$
<<check_version>>
declare
	v_version_old varchar(50) := '1.00.00.002';
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
	set value = '1.00.00.003',
		descr = 'find info',
		date_modified = now(),
		user_modified = "current_user"()
where alias = 'VERSION_DB_NUMBER'
;
update settings
	set value = '16.07.2026',
		descr = '',
		date_modified = now(),
		user_modified = "current_user"()
where alias = 'VERSION_DB_END_DATE' 
;
--######## create table section_type #########################
CREATE TABLE IF NOT EXISTS section_types
(
    id bigint NOT NULL,
    name character varying(25) COLLATE pg_catalog."default",
    descr character varying(100) COLLATE pg_catalog."default",
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_created character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    user_modified character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    CONSTRAINT pk_infotype_id PRIMARY KEY (id)
);

ALTER TABLE IF EXISTS section_types OWNER to kbase;
GRANT ALL ON TABLE section_types TO kbase;

INSERT INTO section_types (id, name, descr)
VALUES 
(1, 'документ', 'Тип Розділу для документів'),
(2, 'словник', 'Тип Розділу для словників')
;

--######## create table icons
CREATE SEQUENCE IF NOT EXISTS seq_icons
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE seq_icons OWNER TO kbase;
-----------------------------------------
CREATE TABLE IF NOT EXISTS icons
(
    id bigint NOT NULL DEFAULT nextval('seq_icons'::regclass),
    parent_id bigint NOT NULL,
    name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    descr character varying(50) COLLATE pg_catalog."default",
    image bytea,
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_id_created bigint NOT NULL,
    user_id_modified bigint NOT NULL,
    CONSTRAINT pk_icons_id PRIMARY KEY (id),
    CONSTRAINT fk_icons_user_id_created FOREIGN KEY (user_id_created)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_icons_user_id_modified FOREIGN KEY (user_id_modified)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

ALTER TABLE IF EXISTS icons OWNER to kbase;
GRANT ALL ON TABLE icons TO kbase;

CREATE INDEX IF NOT EXISTS idx_icons_parent_id ON icons (parent_id ASC NULLS LAST);

--######## create table logs ##################################################
CREATE SEQUENCE IF NOT EXISTS seq_logs
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE seq_logs OWNER TO kbase;
-------------------------------------------------------
CREATE TABLE IF NOT EXISTS logs
(
    id bigint NOT NULL DEFAULT nextval('seq_logs'::regclass),
    log_type character varying(20) COLLATE pg_catalog."default",
    text character varying(255) COLLATE pg_catalog."default",
    date_created timestamp without time zone DEFAULT now(),
    user_id_created bigint NOT NULL,
    CONSTRAINT pk_logs PRIMARY KEY (id),
    CONSTRAINT fk_logs_user_id_created FOREIGN KEY (user_id_created)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

ALTER TABLE IF EXISTS logs OWNER to kbase;
GRANT ALL ON TABLE logs TO kbase;

COMMENT ON TABLE logs IS 'Various logs';
COMMENT ON COLUMN logs.log_type IS 'Log type. For example, error, admin, app.section.delete etc.';

--######## create roles for view #####################################################
-- 1. Create a non‑login role that will hold the read‑only privileges
CREATE ROLE kbase_viewer NOLOGIN;
 
-- 2. Grant read‑only access on the relevant schemas
GRANT USAGE ON SCHEMA kbase TO kbase_viewer;
 
-- 3. Grant SELECT on all existing tables, views, and materialized views
DO $$
DECLARE
    obj RECORD;
BEGIN
    -- tables
    FOR obj IN
        SELECT schemaname, tablename
        FROM pg_tables
        WHERE schemaname IN ('kbase')
    LOOP
        EXECUTE format('GRANT SELECT ON TABLE %I.%I TO kbase_viewer', obj.schemaname, obj.tablename);
    END LOOP;
 
    -- views
    FOR obj IN
        SELECT schemaname, viewname
        FROM pg_views
        WHERE schemaname IN ('kbase')
    LOOP
        EXECUTE format('GRANT SELECT ON TABLE %I.%I TO kbase_viewer', obj.schemaname, obj.viewname);
    END LOOP;
 
    -- materialized views
    FOR obj IN
        SELECT schemaname, matviewname
        FROM pg_matviews
        WHERE schemaname IN ('kbase')
    LOOP
        EXECUTE format('GRANT SELECT ON TABLE %I.%I TO kbase_viewer', obj.schemaname, obj.matviewname);
    END LOOP;
END $$;
 
-- 4. Ensure that any future tables, views, or materialized views created in these schemas
--    automatically grant SELECT to kbase_viewer
ALTER DEFAULT PRIVILEGES IN SCHEMA kbase  GRANT SELECT ON TABLES TO kbase_viewer;
 
-- 5. Create a login role that can connect to the database and inherit the read‑only rights
CREATE ROLE kbase_viewer_ai_agents LOGIN PASSWORD 'kbase';
 
-- 6. Allow the login role to connect to the database
GRANT CONNECT ON DATABASE kbase_web_dev TO kbase_viewer_ai_agents;
 
-- 7. Make the login role a member of the read‑only role
GRANT kbase_viewer TO kbase_viewer_ai_agents;
*/
--######## 




--//TODO create tables - current
/*
--######## create table sections #########################
CREATE SEQUENCE IF NOT EXISTS seq_sections
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE seq_sections OWNER TO kbase;
-----------------------------------------------
CREATE TABLE IF NOT EXISTS sections
(
    id bigint NOT NULL DEFAULT nextval('seq_sections'::regclass),
    parent_id bigint,
    name character varying(255) COLLATE pg_catalog."default",
    descr character varying(255) COLLATE pg_catalog."default",
    section_type_id bigint NOT NULL, -- тип інформації розділу : документ, словник, в перспективі Галерея
    show_level int default 0,    -- 0 - приватний, 1 - для зареєстрованих користувачів, 2 - публічний
    section_category_id bigint NOT NULL, -- категорія розділу (наприклад Заявки-Закрита, Роботи, Документація)
    section_category_id_dir bigint,      -- директорія звідки будуть вибиратися Категорії у Підрозділах
    section_category_id_def bigint,      -- Категорія по замовчуванню для Підрозділів
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    date_modified_info timestamp without time zone,
    user_id_created bigint NOT NULL,
    user_id_modified bigint NOT NULL,
    CONSTRAINT pk_sections_id PRIMARY KEY (id),
    CONSTRAINT fk_sections_section_type_id FOREIGN KEY (section_type_id)
        REFERENCES section_types (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_sections_section_category_id FOREIGN KEY (section_category_id)
        REFERENCES section_categories (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_sections_user_id_created FOREIGN KEY (user_id_created)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_sections_user_id_modified FOREIGN KEY (user_id_modified)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

ALTER TABLE IF EXISTS sections OWNER to kbase;
GRANT ALL ON TABLE kbase.sections TO kbase;

COMMENT ON TABLE sections IS 'Розділи Бази Знань у вигляді дерева';
COMMENT ON COLUMN sections.section_type_id IS 'Тип інформації розділу: 1 - документ, 2 - словник, в перспективі 3 - Галерея';
COMMENT ON COLUMN sections.show_level IS 'Рівень доступу: 0 - приватний, 1 - для зареєстрованих користувачів, 2 - публічний';
COMMENT ON COLUMN sections.section_category_id IS 'Категорія розділу (наприклад: Заявки-Закрита, Роботи, Документація)';
COMMENT ON COLUMN sections.section_category_id_dir IS 'Директорія, звідки будуть вибиратися категорії у підрозділах';
COMMENT ON COLUMN sections.section_category_id_def IS 'Категорія за замовчуванням для підрозділів';
COMMENT ON COLUMN sections.date_modified_info IS 'Остання зміна інфоблоків';

CREATE INDEX IF NOT EXISTS idx_sections_parent_id ON sections (parent_id ASC NULLS LAST);
*/





--// TODO



--<<
