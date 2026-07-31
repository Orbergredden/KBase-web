-->>
SET search_path = kbase, ltree, public, pg_catalog;

-- ######## перевіряємо щоб БД була попередньої версії ############################
do $$
<<check_version>>
declare
	v_version_old varchar(50) := '1.00.00.006';
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
	set value = '1.00.00.007',
		descr = 'ltree suport',
		date_modified = now(),
		user_id_modified = 1
where alias = 'VERSION_DB_NUMBER'
;
update settings
	set value = '29.07.2026',
		descr = '',
		date_modified = now(),
		user_id_modified = 1
where alias = 'VERSION_DB_END_DATE' 
;

--######## add field section_path #####################################
-- 1. Увімкнення розширення
CREATE EXTENSION IF NOT EXISTS ltree;

-- 2. Додати колонку section_path до існуючої таблиці sections
ALTER TABLE sections 
ADD COLUMN section_path ltree;

-- 3. Створити індекси для швидкого пошуку
-- GIST індекс — для операторів @>, <@, ~ (пошук предків/нащадків)
CREATE INDEX idx_sections_path_gist ON sections USING GIST (section_path);

-- BTREE індекс — для сортування, групування, унікальності
CREATE INDEX idx_sections_path_btree ON sections USING BTREE (section_path);

--######## add triggers #################################################
-- Функція для автоматичного розрахунку шляху при INSERT
CREATE OR REPLACE FUNCTION trg_section_set_path()
RETURNS TRIGGER AS $$
-- Функція для автоматичного розрахунку шляху при INSERT
BEGIN
    IF NEW.parent_id IS NULL THEN
        -- Кореневий розділ: шлях = свій ID
        NEW.section_path := NEW.id::text;
    ELSE
        -- Дочірній розділ: шлях = шлях_батька + свій_ID
        SELECT parent.section_path || NEW.id::text
        INTO NEW.section_path
        FROM sections parent
        WHERE parent.id = NEW.parent_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Тригер на INSERT
CREATE TRIGGER trigger_section_set_path
BEFORE INSERT ON sections
FOR EACH ROW EXECUTE FUNCTION trg_section_set_path();

-- Функція для оновлення шляхів при зміні parent_id (переміщення гілки)
CREATE OR REPLACE FUNCTION trg_section_update_path_on_move()
RETURNS TRIGGER AS $$
-- Функція для оновлення шляхів при зміні parent_id (переміщення гілки)
DECLARE
    old_path ltree;
    new_path ltree;
BEGIN
    -- Якщо parent_id не змінився — нічого не робимо
    IF OLD.parent_id IS NOT DISTINCT FROM NEW.parent_id THEN
        RETURN NEW;
    END IF;

    -- Зберігаємо старий шлях
    old_path := OLD.section_path;

    -- Розраховуємо новий шлях (як при INSERT)
    IF NEW.parent_id IS NULL THEN
        new_path := NEW.id::text;
    ELSE
        SELECT parent.section_path || NEW.id::text
        INTO new_path
        FROM sections parent
        WHERE parent.id = NEW.parent_id;
    END IF;

    -- Оновлюємо поточний рядок
    NEW.section_path := new_path;

    -- Оновлюємо ВСІХ нащадків (рекурсивно через ltree)
    UPDATE sections
    SET section_path = new_path || subpath(section_path, nlevel(old_path))
    WHERE section_path <@ old_path
      AND id != NEW.id;  -- не оновлюємо себе ще раз

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Тригер на UPDATE (переміщення гілки)
CREATE TRIGGER trigger_section_update_path_on_move
BEFORE UPDATE OF parent_id ON sections
FOR EACH ROW EXECUTE FUNCTION trg_section_update_path_on_move();

--######## rename triggers ##################################################
-- Rename function trg_update_section_date_modified_info -> trg_section_update_date_modified_info
ALTER FUNCTION kbase.trg_update_section_date_modified_info() 
	RENAME TO trg_section_update_date_modified_info;

-- Rename trigger trg_section_dictionaries_update_section_info -> trigger_section_dictionaries_update_section_info
ALTER TRIGGER trg_section_dictionaries_update_section_info ON kbase.section_dictionaries 
	RENAME TO trigger_section_dictionaries_update_sections;

-- Rename trigger trg_section_document_info_block_headers_update_section_info -> trigger_section_document_info_block_headers_update_section_info
ALTER TRIGGER trg_section_document_info_block_headers_update_section_info ON kbase.section_document_info_block_headers 
	RENAME TO trigger_section_document_info_block_headers_update_sections;

-- Drop and recreate trigger on section_dictionaries with new function name
DROP TRIGGER trigger_section_dictionaries_update_sections ON kbase.section_dictionaries;
CREATE TRIGGER trigger_section_dictionaries_update_sections
  AFTER INSERT OR DELETE OR UPDATE ON kbase.section_dictionaries
  FOR EACH ROW EXECUTE FUNCTION kbase.trg_section_update_date_modified_info();

-- Drop and recreate trigger on section_document_info_block_headers with new function name
DROP TRIGGER trigger_section_document_info_block_headers_update_sections ON kbase.section_document_info_block_headers;
CREATE TRIGGER trigger_section_document_info_block_headers_update_sections
  AFTER INSERT OR DELETE OR UPDATE ON kbase.section_document_info_block_headers
  FOR EACH ROW EXECUTE FUNCTION kbase.trg_section_update_date_modified_info();

--######## move ltree ################################################################
-- ============================================================
-- PHASE 1: Move ltree extension to dedicated schema
-- ============================================================

-- 1. Create target schema
CREATE SCHEMA IF NOT EXISTS ltree;

-- 2. Move extension (this moves all 24 extension functions/types to ltree schema)
ALTER EXTENSION ltree SET SCHEMA ltree;

-- 3. Verify extension objects moved
SELECT n.nspname, p.proname 
FROM pg_proc p 
JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname = 'ltree' AND p.proname LIKE 'ltree%'
ORDER BY p.proname;

-- ============================================================
-- PHASE 2: Update user-defined functions to use ltree.ltree
-- ============================================================

-- Option B: Or update functions explicitly (more explicit, no search_path dependency)
-- UPDATE trg_section_set_path to use ltree.ltree explicitly
CREATE OR REPLACE FUNCTION kbase.trg_section_set_path()
RETURNS TRIGGER LANGUAGE plpgsql AS $function$
-- Функція для автоматичного розрахунку шляху при INSERT
BEGIN
    IF NEW.parent_id IS NULL THEN
        NEW.section_path := NEW.id::text::ltree.ltree;
    ELSE
        SELECT parent.section_path || NEW.id::text::ltree.ltree
        INTO NEW.section_path
        FROM kbase.sections parent
        WHERE parent.id = NEW.parent_id;
    END IF;
    RETURN NEW;
END;
$function$;

-- UPDATE trg_section_update_path_on_move to use ltree.ltree explicitly
CREATE OR REPLACE FUNCTION kbase.trg_section_update_path_on_move()
RETURNS TRIGGER LANGUAGE plpgsql AS $function$
-- Функція для оновлення шляхів при зміні parent_id (переміщення гілки)
DECLARE
    old_path ltree.ltree;
    new_path ltree.ltree;
BEGIN
    -- Якщо parent_id не змінився — нічого не робимо
    IF OLD.parent_id IS NOT DISTINCT FROM NEW.parent_id THEN
        RETURN NEW;
    END IF;

    -- Зберігаємо старий шлях
    old_path := OLD.section_path;

    -- Розраховуємо новий шлях (як при INSERT)
    IF NEW.parent_id IS NULL THEN
        new_path := NEW.id::text::ltree.ltree;
    ELSE
        SELECT parent.section_path || NEW.id::text::ltree.ltree
        INTO new_path
        FROM kbase.sections parent
        WHERE parent.id = NEW.parent_id;
    END IF;

    -- Оновлюємо поточний рядок
    NEW.section_path := new_path;

    -- Оновлюємо ВСІХ нащадків (рекурсивно через ltree)
    UPDATE kbase.sections
    SET section_path = new_path || subpath(section_path, nlevel(old_path))
    WHERE section_path <@ old_path
      AND id != NEW.id;

    RETURN NEW;
END;
$function$;

GRANT USAGE ON SCHEMA ltree TO kbase, kbase_viewer;
--<<
