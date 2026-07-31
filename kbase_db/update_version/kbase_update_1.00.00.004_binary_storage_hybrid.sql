-- ============================================================
-- Міграція: Гібридне зберігання бінарних даних
-- Таблиця: kbase.section_document_info_block_components_binary
-- ============================================================

SET search_path = kbase, public, pg_catalog;

-- 1. Перевірка версії БД
DO $$
<<check_version>>
DECLARE
    v_version_old VARCHAR(50) := '1.00.00.003';
    v_version     VARCHAR(50);
BEGIN
    SELECT s.value INTO v_version
    FROM settings s
    WHERE s.alias = 'VERSION_DB_NUMBER';
    IF v_version_old <> v_version THEN
        RAISE EXCEPTION 'DB version mismatch: expected %, current %', v_version_old, v_version;
    END IF;
END check_version $$;

-- 2. Оновлення версії
UPDATE settings SET value = '1.00.00.004', descr = 'hybrid binary storage (DB/FS/S3)', date_modified = now(), user_modified = "current_user"() WHERE alias = 'VERSION_DB_NUMBER';
UPDATE settings SET value = '24.07.2026', descr = '', date_modified = now(), user_modified = "current_user"() WHERE alias = 'VERSION_DB_END_DATE';

-- 3. Видалення старої таблиці (CASCADE видалить залежності)
DROP TABLE IF EXISTS section_document_info_block_components_binary CASCADE;

-- 4. Sequence
CREATE SEQUENCE IF NOT EXISTS seq_section_document_info_block_components_binary
    INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;
ALTER SEQUENCE seq_section_document_info_block_components_binary OWNER TO kbase;

-- 5. Нова таблиця з гібридним зберіганням
CREATE TABLE section_document_info_block_components_binary
(
    id                                              BIGINT NOT NULL DEFAULT nextval('seq_section_document_info_block_components_binary'::regclass),
    section_document_info_block_header_id           BIGINT NOT NULL,
    section_document_info_block_type_component_id   BIGINT NOT NULL,

    -- === Гібридне зберігання ===
    storage_type                                    SMALLINT NOT NULL DEFAULT 1,  -- 1=DB(bytea), 2=FS(path), 3=S3(key)
    value                                           BYTEA,                        -- дані для storage_type=1
    file_path                                       VARCHAR(500),                 -- шлях FS або S3 key для storage_type=2,3
    file_size                                       BIGINT,                       -- розмір у байтах
    mime_type                                       VARCHAR(100),                 -- image/png, application/pdf, ...
    original_filename                               VARCHAR(255),                 -- оригінальна назва файлу
    checksum                                        VARCHAR(64),                  -- SHA-256 hex

    -- === Аудіт ===
    date_created                                    TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    date_modified                                   TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    user_id_created                                 BIGINT NOT NULL,
    user_id_modified                                BIGINT NOT NULL,

    CONSTRAINT pk_section_document_info_block_components_binary_id PRIMARY KEY (id),
    CONSTRAINT fk_section_document_info_block_components_binary_header_id
        FOREIGN KEY (section_document_info_block_header_id)
        REFERENCES section_document_info_block_headers (id)
        MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT fk_section_document_info_block_components_binary_type_component_id
        FOREIGN KEY (section_document_info_block_type_component_id)
        REFERENCES section_document_info_block_type_components (id)
        MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_section_document_info_block_components_binary_user_id_created
        FOREIGN KEY (user_id_created) REFERENCES users (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_section_document_info_block_components_binary_user_id_modified
        FOREIGN KEY (user_id_modified) REFERENCES users (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,

    -- Перевірка storage_type
    CONSTRAINT chk_storage_type CHECK (storage_type IN (1, 2, 3)),

    -- Логічна цілісність даних
    CONSTRAINT chk_storage_data_consistency CHECK (
        (storage_type = 1 AND value IS NOT NULL AND file_path IS NULL)
        OR
        (storage_type IN (2, 3) AND file_path IS NOT NULL AND value IS NULL)
    )
);

ALTER TABLE section_document_info_block_components_binary OWNER TO kbase;
GRANT ALL ON TABLE section_document_info_block_components_binary TO kbase;

-- 6. Коментарі
COMMENT ON TABLE section_document_info_block_components_binary IS
'Компоненти типів 2 - картинка, 3 - файл. Гібридне зберігання: 1=DB(bytea), 2=FS(path), 3=S3(key)';

COMMENT ON COLUMN section_document_info_block_components_binary.section_document_info_block_header_id IS 'Заголовок інфо блоку';
COMMENT ON COLUMN section_document_info_block_components_binary.section_document_info_block_type_component_id IS 'Тип компонента';
COMMENT ON COLUMN section_document_info_block_components_binary.storage_type IS 'Тип сховища: 1=DB(bytea), 2=FileSystem(path), 3=S3(key)';
COMMENT ON COLUMN section_document_info_block_components_binary.value IS 'Бінарні дані (тільки для storage_type=1)';
COMMENT ON COLUMN section_document_info_block_components_binary.file_path IS 'Шлях на FS або S3 object key (для storage_type=2,3)';
COMMENT ON COLUMN section_document_info_block_components_binary.file_size IS 'Розмір файлу у байтах';
COMMENT ON COLUMN section_document_info_block_components_binary.mime_type IS 'MIME тип: image/png, application/pdf, ...';
COMMENT ON COLUMN section_document_info_block_components_binary.original_filename IS 'Оригінальна назва файлу при завантаженні';
COMMENT ON COLUMN section_document_info_block_components_binary.checksum IS 'SHA-256 hex для дедуплікації та перевірки цілісності';

-- 7. Індекси
CREATE INDEX idx_section_document_info_block_components_binary_header_id
    ON section_document_info_block_components_binary (section_document_info_block_header_id);

CREATE INDEX idx_section_document_info_block_components_binary_type_component_id
    ON section_document_info_block_components_binary (section_document_info_block_type_component_id);

CREATE INDEX idx_section_document_info_block_components_binary_storage_type
    ON section_document_info_block_components_binary (storage_type);
