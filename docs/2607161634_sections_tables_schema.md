# Роблю структуру даних для Розділів

section_document_info_block_headers  -- заголовки інфо блоків Розділів
    id 
    section_id 
    section_document_info_block_type_id  -- тип інформаційного блока (текст, картинка, файл, ...)
    section_document_info_block_style_id   -- стиль показу інфо блока
    "position" bigint, -- позиція в списку інфо блоків Розділа
    name 
    descr
    date/user





kbase.info_block_components_text  -- тут зберігаються компоненти типів 1 - текст
    id bigint NOT NULL DEFAULT nextval('kbase.seq_info'::regclass),
    info_block_header_id bigint NOT NULL,
    info_block_type_component_id bigint NOT NULL,  -- 
    "value" text 

kbase.info_block_components_binary  -- тут зберігаються компоненти типів 2 - картинка, 3 - файл
    id bigint NOT NULL DEFAULT nextval('kbase.seq_info'::regclass),
    info_block_header_id bigint NOT NULL,
    info_block_type_component_id bigint NOT NULL,  -- 
    "value" bytea 

kbase.info_block_components_number  -- тут зберігаються компоненти типів 4 - ціле число, 5 - логічне значення
    id bigint NOT NULL DEFAULT nextval('kbase.seq_info'::regclass),
    info_block_header_id bigint NOT NULL,
    info_block_type_component_id bigint NOT NULL,  -- 
    "value" bigint
