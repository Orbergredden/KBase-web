-->>
/*
CREATE DATABASE kbase_web_dev
    WITH
    OWNER = kbase
    TEMPLATE = template0
    ENCODING = 'UTF8'
    LC_COLLATE = 'uk_UA.UTF-8'
    LC_CTYPE = 'uk_UA.UTF-8'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

\c kbase_web_dev

CREATE SCHEMA IF NOT EXISTS kbase AUTHORIZATION kbase;

SET client_encoding = 'UTF8';
SET lc_messages TO 'en_US.UTF-8';

SET search_path = kbase, public, pg_catalog;

--######## create table settings ################################
CREATE SEQUENCE IF NOT EXISTS seq_settings
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE seq_settings
    OWNER TO kbase;

CREATE TABLE IF NOT EXISTS settings
(
    id bigint NOT NULL DEFAULT nextval('seq_settings'::regclass),
    alias character varying(50) COLLATE pg_catalog."default" NOT NULL,
    section character varying(50) COLLATE pg_catalog."default",
    subject character varying(50) COLLATE pg_catalog."default",
    name character varying(50) COLLATE pg_catalog."default",
    value character varying(50) COLLATE pg_catalog."default",
    descr character varying(200) COLLATE pg_catalog."default",
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_created character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    user_modified character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    CONSTRAINT pk_settings_id PRIMARY KEY (id),
    CONSTRAINT k_settings_alias UNIQUE (alias)
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS settings
    OWNER to kbase;

GRANT ALL ON TABLE settings TO kbase;

COMMENT ON TABLE settings
    IS 'Для збереження налаштувань програми на рівні БД.';
COMMENT ON COLUMN settings.alias
    IS 'Текстовий унікальний ідентифікатор';
COMMENT ON COLUMN settings.user_created
    IS 'Той, хто створив запис';
COMMENT ON COLUMN settings.user_modified
    IS 'Той, хто вносив останні зміни до запису';

CREATE UNIQUE INDEX IF NOT EXISTS ind_settings_alias
    ON settings USING btree
    (alias COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
*/
INSERT INTO settings (alias,"section",subject,"name",value,descr) VALUES
	 ('VERSION_DB_BEGIN_DATE','Version','Db','Begin date','05.07.2026',''),
	 ('VERSION_DB_NUMBER'    ,'Version','Db','number',    '1.00.00.001','begin'),
	 ('VERSION_DB_END_DATE'  ,'Version','Db','End date',  '05.07.2026','')
;






--<<

