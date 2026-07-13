-->>
SET search_path = kbase, public, pg_catalog;

--######## create sequences ################################
CREATE SEQUENCE IF NOT EXISTS seq_roles
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS seq_privileges
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS seq_users
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS seq_refresh_tokens
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

--######## create table roles ################################
CREATE TABLE IF NOT EXISTS roles
(
    id bigint NOT NULL DEFAULT nextval('seq_roles'::regclass),
    name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    descr character varying(200) COLLATE pg_catalog."default",
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_created character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    user_modified character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    CONSTRAINT pk_roles_id PRIMARY KEY (id),
    CONSTRAINT k_roles_name UNIQUE (name)
)
TABLESPACE pg_default;

--######## create table privileges ################################
CREATE TABLE IF NOT EXISTS privileges
(
    id bigint NOT NULL DEFAULT nextval('seq_privileges'::regclass),
    name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    descr character varying(200) COLLATE pg_catalog."default",
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_created character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    user_modified character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    CONSTRAINT pk_privileges_id PRIMARY KEY (id),
    CONSTRAINT k_privileges_name UNIQUE (name)
)
TABLESPACE pg_default;

--######## create table role_privileges ################################
CREATE TABLE IF NOT EXISTS role_privileges
(
    role_id bigint NOT NULL,
    privilege_id bigint NOT NULL,
    CONSTRAINT pk_role_privileges PRIMARY KEY (role_id, privilege_id),
    CONSTRAINT fk_role_privileges_role FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE,
    CONSTRAINT fk_role_privileges_privilege FOREIGN KEY (privilege_id) REFERENCES privileges (id) ON DELETE CASCADE
)
TABLESPACE pg_default;

--######## create table users ################################
CREATE TABLE IF NOT EXISTS users
(
    id bigint NOT NULL DEFAULT nextval('seq_users'::regclass),
    username character varying(50) COLLATE pg_catalog."default" NOT NULL,
    password character varying(100) COLLATE pg_catalog."default" NOT NULL,
    email character varying(100) COLLATE pg_catalog."default",
    role_id bigint,
    active boolean NOT NULL DEFAULT true,
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_created character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    user_modified character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    CONSTRAINT pk_users_id PRIMARY KEY (id),
    CONSTRAINT k_users_username UNIQUE (username),
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE SET NULL
)
TABLESPACE pg_default;

--######## create table refresh_tokens ################################
CREATE TABLE IF NOT EXISTS refresh_tokens
(
    id bigint NOT NULL DEFAULT nextval('seq_refresh_tokens'::regclass),
    token character varying(255) COLLATE pg_catalog."default" NOT NULL,
    user_id bigint NOT NULL,
    expiry_date timestamp without time zone NOT NULL,
    CONSTRAINT pk_refresh_tokens_id PRIMARY KEY (id),
    CONSTRAINT k_refresh_tokens_token UNIQUE (token),
    CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
)
TABLESPACE pg_default;

--######## set owners and permissions ################################
ALTER SEQUENCE seq_roles OWNER TO kbase;
ALTER SEQUENCE seq_privileges OWNER TO kbase;
ALTER SEQUENCE seq_users OWNER TO kbase;
ALTER SEQUENCE seq_refresh_tokens OWNER TO kbase;

ALTER TABLE roles OWNER to kbase;
ALTER TABLE privileges OWNER to kbase;
ALTER TABLE role_privileges OWNER to kbase;
ALTER TABLE users OWNER to kbase;
ALTER TABLE refresh_tokens OWNER to kbase;

GRANT ALL ON TABLE roles TO kbase;
GRANT ALL ON TABLE privileges TO kbase;
GRANT ALL ON TABLE role_privileges TO kbase;
GRANT ALL ON TABLE users TO kbase;
GRANT ALL ON TABLE refresh_tokens TO kbase;

--######## insert default dictionary data ################################
INSERT INTO roles (name, descr) VALUES 
('ROLE_ADMIN', 'Адміністратор системи з повним доступом'),
('ROLE_USER', 'Користувач системи з правом перегляду та редагування')
ON CONFLICT (name) DO NOTHING;

INSERT INTO privileges (name, descr) VALUES 
('READ_PRIVILEGE', 'Дозвіл на перегляд Бази Знань'),
('WRITE_PRIVILEGE', 'Дозвіл на додавання/редагування статей'),
('DELETE_PRIVILEGE', 'Дозвіл на видалення статей'),
('ADMIN_PRIVILEGE', 'Дозвіл на адміністрування користувачів')
ON CONFLICT (name) DO NOTHING;

-- Link ROLE_ADMIN to all privileges
INSERT INTO role_privileges (role_id, privilege_id)
SELECT r.id, p.id FROM roles r, privileges p
WHERE r.name = 'ROLE_ADMIN' AND p.name IN ('READ_PRIVILEGE', 'WRITE_PRIVILEGE', 'DELETE_PRIVILEGE', 'ADMIN_PRIVILEGE')
ON CONFLICT DO NOTHING;

-- Link ROLE_USER to READ and WRITE privileges
INSERT INTO role_privileges (role_id, privilege_id)
SELECT r.id, p.id FROM roles r, privileges p
WHERE r.name = 'ROLE_USER' AND p.name IN ('READ_PRIVILEGE', 'WRITE_PRIVILEGE')
ON CONFLICT DO NOTHING;

--######## insert default users ################################
-- Passwords BCrypt-hashed:
-- 'admin' -> $2a$10$dXJ3ADWyyTXFlKtyTqchPu57sOHVCx3c6ghf3q7/c6qR9Xl6Jj8W.
-- 'user' -> $2a$10$lRy.xVwXkQy5m42hP6g85eV9l3XgA/uB1wXq/l94G1vX6/5hU5pDe
INSERT INTO users (username, password, email, role_id, active)
SELECT 'admin', '$2a$10$dXJ3ADWyyTXFlKtyTqchPu57sOHVCx3c6ghf3q7/c6qR9Xl6Jj8W.', 'admin@kbase.ua', r.id, true
FROM roles r WHERE r.name = 'ROLE_ADMIN'
ON CONFLICT (username) DO NOTHING;

INSERT INTO users (username, password, email, role_id, active)
SELECT 'user', '$2a$10$lRy.xVwXkQy5m42hP6g85eV9l3XgA/uB1wXq/l94G1vX6/5hU5pDe', 'user@kbase.ua', r.id, true
FROM roles r WHERE r.name = 'ROLE_USER'
ON CONFLICT (username) DO NOTHING;

--######## update settings version ################################
UPDATE settings SET value = '1.00.00.002' WHERE alias = 'VERSION_DB_NUMBER';
UPDATE settings SET value = '08.07.2026' WHERE alias = 'VERSION_DB_END_DATE';

--<<
