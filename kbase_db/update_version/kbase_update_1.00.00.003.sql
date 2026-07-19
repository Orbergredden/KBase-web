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

--######## create table template_color_themes #########################
CREATE SEQUENCE IF NOT EXISTS seq_template_color_themes
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE seq_template_color_themes OWNER TO kbase;
-----------------------------------------
CREATE TABLE IF NOT EXISTS template_color_themes
(
    id bigint NOT NULL DEFAULT nextval('seq_template_color_themes'::regclass),
    name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    type character varying(10) COLLATE pg_catalog."default" NOT NULL CHECK (type IN ('light', 'dark')),
    is_default boolean NOT NULL DEFAULT false,
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_id_created bigint NOT NULL,
    user_id_modified bigint NOT NULL,
    CONSTRAINT pk_template_color_themes_id PRIMARY KEY (id),
    CONSTRAINT fk_template_color_themes_user_id_created FOREIGN KEY (user_id_created)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_template_color_themes_user_id_modified FOREIGN KEY (user_id_modified)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

ALTER TABLE IF EXISTS template_color_themes OWNER to kbase;
GRANT ALL ON TABLE template_color_themes TO kbase;

COMMENT ON TABLE template_color_themes IS 'Кольорові теми для шаблонів';
COMMENT ON COLUMN template_color_themes.type IS 'Тип теми: light - світла, dark - темна';
COMMENT ON COLUMN template_color_themes.is_default IS 'Теми за замовчуванням, повинна бути одна світла і одна темна';

INSERT INTO template_color_themes (id, name, type, is_default, user_id_created, user_id_modified)
VALUES 
(1, 'Стандартна світла', 'light', true, 1, 1),
(2, 'Стандартна темна', 'dark', true, 1, 1)
ON CONFLICT (id) DO NOTHING;

--######## create table templates #########################
CREATE SEQUENCE IF NOT EXISTS seq_templates
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE seq_templates OWNER TO kbase;
-----------------------------------------------
CREATE TABLE IF NOT EXISTS templates
(
    id bigint NOT NULL DEFAULT nextval('seq_templates'::regclass),
    parent_id bigint,
    is_dir boolean NOT NULL DEFAULT false,
    is_reserved boolean NOT NULL DEFAULT false,
    name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    descr character varying(500) COLLATE pg_catalog."default",
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_id_created bigint NOT NULL,
    user_id_modified bigint NOT NULL,
    CONSTRAINT pk_templates_id PRIMARY KEY (id),
    CONSTRAINT fk_templates_parent_id FOREIGN KEY (parent_id)
        REFERENCES templates (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT fk_templates_user_id_created FOREIGN KEY (user_id_created)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_templates_user_id_modified FOREIGN KEY (user_id_modified)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

ALTER TABLE IF EXISTS templates OWNER to kbase;
GRANT ALL ON TABLE templates TO kbase;

COMMENT ON TABLE templates IS 'Шаблони документів у вигляді дерева (директорії та шаблони)';
COMMENT ON COLUMN templates.parent_id IS 'Батьківський елемент (для деревової структури)';
COMMENT ON COLUMN templates.is_dir IS 'true - директорія, false - шаблон (кінцевий елемент)';
COMMENT ON COLUMN templates.is_reserved IS 'Зарезервовані елементи';

CREATE INDEX IF NOT EXISTS idx_templates_parent_id ON templates (parent_id ASC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_templates_is_dir ON templates (is_dir);

--######## create table template_bodies #########################
CREATE SEQUENCE IF NOT EXISTS seq_template_bodies
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE seq_template_bodies OWNER TO kbase;
-----------------------------------------
CREATE TABLE IF NOT EXISTS template_bodies
(
    id bigint NOT NULL DEFAULT nextval('seq_template_bodies'::regclass),
    template_id bigint NOT NULL,
    template_color_theme_id bigint NOT NULL,
    body text COLLATE pg_catalog."default",
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_id_created bigint NOT NULL,
    user_id_modified bigint NOT NULL,
    CONSTRAINT pk_template_bodies_id PRIMARY KEY (id),
    CONSTRAINT fk_template_bodies_template_id FOREIGN KEY (template_id)
        REFERENCES templates (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT fk_template_bodies_template_color_theme_id FOREIGN KEY (template_color_theme_id)
        REFERENCES template_color_themes (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_template_bodies_user_id_created FOREIGN KEY (user_id_created)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_template_bodies_user_id_modified FOREIGN KEY (user_id_modified)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT uk_template_bodies_template_theme UNIQUE (template_id, template_color_theme_id)
);

ALTER TABLE IF EXISTS template_bodies OWNER to kbase;
GRANT ALL ON TABLE template_bodies TO kbase;

COMMENT ON TABLE template_bodies IS 'Тіла шаблонів для кожної кольорової теми';
COMMENT ON COLUMN template_bodies.body IS 'HTML/текст тіла шаблону';

CREATE INDEX IF NOT EXISTS idx_template_bodies_template_id ON template_bodies (template_id);
CREATE INDEX IF NOT EXISTS idx_template_bodies_template_color_theme_id ON template_bodies (template_color_theme_id);

--######## create table template_files #########################
CREATE SEQUENCE IF NOT EXISTS seq_template_files
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE seq_template_files OWNER TO kbase;
-----------------------------------------------
CREATE TABLE IF NOT EXISTS template_files
(
    id bigint NOT NULL DEFAULT nextval('seq_template_files'::regclass),
    parent_id bigint,
    is_dir boolean NOT NULL DEFAULT false,
    is_reserved boolean NOT NULL DEFAULT false,
    file_type smallint NOT NULL CHECK (file_type IN (1, 2, 3)),
    file_name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    descr character varying(255) COLLATE pg_catalog."default",
    body text COLLATE pg_catalog."default",
    body_bin bytea,
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_id_created bigint NOT NULL,
    user_id_modified bigint NOT NULL,
    CONSTRAINT pk_template_files_id PRIMARY KEY (id),
    CONSTRAINT fk_template_files_parent_id FOREIGN KEY (parent_id)
        REFERENCES template_files (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT fk_template_files_user_id_created FOREIGN KEY (user_id_created)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_template_files_user_id_modified FOREIGN KEY (user_id_modified)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

ALTER TABLE IF EXISTS template_files OWNER to kbase;
GRANT ALL ON TABLE template_files TO kbase;

COMMENT ON TABLE template_files IS 'Файли шаблонів (картинки, CSS, JS, бінарні) у вигляді дерева';
COMMENT ON COLUMN template_files.parent_id IS 'Батьківська директорія';
COMMENT ON COLUMN template_files.is_dir IS 'true - директорія, false - файл';
COMMENT ON COLUMN template_files.is_reserved IS 'Зарезервовані файли, ті що використовуються в шаблонах';
COMMENT ON COLUMN template_files.file_type IS 'Тип файлу: 1 - текстовий, 2 - картинка, 3 - бінарний';
COMMENT ON COLUMN template_files.body IS 'Вміст текстового файлу';
COMMENT ON COLUMN template_files.body_bin IS 'Вміст бінарного файлу';

CREATE INDEX IF NOT EXISTS idx_template_files_parent_id ON template_files (parent_id ASC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_template_files_is_dir ON template_files (is_dir);
CREATE INDEX IF NOT EXISTS idx_template_files_is_reserved ON template_files (is_reserved);

--######## create table section_categories #########################
CREATE SEQUENCE IF NOT EXISTS seq_section_categories
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE seq_section_categories OWNER TO kbase;
-----------------------------------------
CREATE TABLE IF NOT EXISTS section_categories
(
    id bigint NOT NULL DEFAULT nextval('seq_section_categories'::regclass),
    parent_id bigint,
    name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    descr character varying(500) COLLATE pg_catalog."default",
    icon_id bigint,
    template_id bigint,
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_id_created bigint NOT NULL,
    user_id_modified bigint NOT NULL,
    CONSTRAINT pk_section_categories_id PRIMARY KEY (id),
    CONSTRAINT fk_section_categories_parent_id FOREIGN KEY (parent_id)
        REFERENCES section_categories (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT fk_section_categories_icon_id FOREIGN KEY (icon_id)
        REFERENCES icons (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_section_categories_template_id FOREIGN KEY (template_id)
        REFERENCES templates (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_section_categories_user_id_created FOREIGN KEY (user_id_created)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_section_categories_user_id_modified FOREIGN KEY (user_id_modified)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

ALTER TABLE IF EXISTS section_categories OWNER to kbase;
GRANT ALL ON TABLE section_categories TO kbase;

COMMENT ON TABLE section_categories IS 'Категорії Розділів у вигляді дерева';
COMMENT ON COLUMN section_categories.parent_id IS 'Батьківська категорія';
COMMENT ON COLUMN section_categories.icon_id IS 'Іконка категорії';
COMMENT ON COLUMN section_categories.template_id IS 'Шаблон для розділів цієї категорії';

CREATE INDEX IF NOT EXISTS idx_section_categories_parent_id ON section_categories (parent_id ASC NULLS LAST);

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

--######## create table section_document_info_block_type #########################
CREATE SEQUENCE IF NOT EXISTS seq_section_document_info_block_type
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE seq_section_document_info_block_type OWNER TO kbase;
-----------------------------------------
CREATE TABLE IF NOT EXISTS section_document_info_block_type
(
    id bigint NOT NULL DEFAULT nextval('seq_section_document_info_block_type'::regclass),
    name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    descr character varying(500) COLLATE pg_catalog."default",
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_id_created bigint NOT NULL,
    user_id_modified bigint NOT NULL,
    CONSTRAINT pk_section_document_info_block_type_id PRIMARY KEY (id),
    CONSTRAINT fk_section_document_info_block_type_user_id_created FOREIGN KEY (user_id_created)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_section_document_info_block_type_user_id_modified FOREIGN KEY (user_id_modified)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

ALTER TABLE IF EXISTS section_document_info_block_type OWNER to kbase;
GRANT ALL ON TABLE section_document_info_block_type TO kbase;

COMMENT ON TABLE section_document_info_block_type IS 'Типи інфоблоків для документів';
COMMENT ON COLUMN section_document_info_block_type.name IS 'Назва типу інфоблоку';

INSERT INTO section_document_info_block_type (id, name, descr, user_id_created, user_id_modified)
VALUES 
(1, 'Текст', 'Текстовий інфоблок', 1, 1),
(2, 'Картинка', 'Інфоблок зображення', 1, 1),
(3, 'Файл', 'Інфоблок файлу', 1, 1)
ON CONFLICT (id) DO NOTHING;

--######## create table section_document_info_block_type_components #########################
CREATE SEQUENCE IF NOT EXISTS seq_section_document_info_block_type_components
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE seq_section_document_info_block_type_components OWNER TO kbase;
-----------------------------------------
CREATE TABLE IF NOT EXISTS section_document_info_block_type_components
(
    id bigint NOT NULL DEFAULT nextval('seq_section_document_info_block_type_components'::regclass),
    section_document_info_block_type_id bigint NOT NULL,
    name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    descr character varying(500) COLLATE pg_catalog."default",
    component_type smallint NOT NULL CHECK (component_type IN (1, 2, 3, 4, 5)),
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_id_created bigint NOT NULL,
    user_id_modified bigint NOT NULL,
    CONSTRAINT pk_section_document_info_block_type_components_id PRIMARY KEY (id),
    CONSTRAINT fk_section_document_info_block_type_components_type_id FOREIGN KEY (section_document_info_block_type_id)
        REFERENCES section_document_info_block_type (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT fk_section_document_info_block_type_components_user_id_created FOREIGN KEY (user_id_created)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_section_document_info_block_type_components_user_id_modified FOREIGN KEY (user_id_modified)
        REFERENCES users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

ALTER TABLE IF EXISTS section_document_info_block_type_components OWNER to kbase;
GRANT ALL ON TABLE section_document_info_block_type_components TO kbase;

COMMENT ON TABLE section_document_info_block_type_components IS 'Компоненти, з яких складається тип інфоблоку';
COMMENT ON COLUMN section_document_info_block_type_components.component_type IS 'Тип компонента: 1 - текст, 2 - картинка, 3 - файл, 4 - ціле число, 5 - логічне значення';

-- Components for "Текст" (id=1)
INSERT INTO section_document_info_block_type_components (id, section_document_info_block_type_id, name, descr, component_type, user_id_created, user_id_modified)
VALUES 
(1, 1, 'title', 'Заголовок', 1, 1, 1),
(2, 1, 'text', 'Текст', 1, 1, 1),
(3, 1, 'is_show_title', 'Показувати заголовок', 5, 1, 1)
ON CONFLICT (id) DO NOTHING;

-- Components for "Картинка" (id=2)
INSERT INTO section_document_info_block_type_components (id, section_document_info_block_type_id, name, descr, component_type, user_id_created, user_id_modified)
VALUES 
(4, 2, 'title', 'Заголовок', 1, 1, 1),
(5, 2, 'image', 'Зображення', 2, 1, 1),
(6, 2, 'width', 'Ширина', 4, 1, 1),
(7, 2, 'height', 'Висота', 4, 1, 1),
(8, 2, 'descr', 'Опис', 1, 1, 1),
(9, 2, 'text', 'Текст', 1, 1, 1),
(10, 2, 'is_show_title', 'Показувати заголовок', 5, 1, 1),
(11, 2, 'is_show_descr', 'Показувати опис', 5, 1, 1),
(12, 2, 'is_show_text', 'Показувати текст', 5, 1, 1)
ON CONFLICT (id) DO NOTHING;

-- Components for "Файл" (id=3)
INSERT INTO section_document_info_block_type_components (id, section_document_info_block_type_id, name, descr, component_type, user_id_created, user_id_modified)
VALUES 
(13, 3, 'title', 'Заголовок', 1, 1, 1),
(14, 3, 'file_body', 'Вміст файлу', 3, 1, 1),
(15, 3, 'file_name', 'Назва файлу', 1, 1, 1),
(16, 3, 'icon_id', 'Іконка файлу', 4, 1, 1),
(17, 3, 'descr', 'Опис', 1, 1, 1),
(18, 3, 'text', 'Текст', 1, 1, 1),
(19, 3, 'is_show_title', 'Показувати заголовок', 5, 1, 1),
(20, 3, 'is_show_descr', 'Показувати опис', 5, 1, 1),
(21, 3, 'is_show_text', 'Показувати текст', 5, 1, 1)
ON CONFLICT (id) DO NOTHING;
*/




--<<
