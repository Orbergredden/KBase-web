# Роблю структуру даних для Розділів

kbase.info_block_headers  -- заголовки інфо блоків Розділів
    id bigint NOT NULL DEFAULT nextval('kbase.seq_info'::regclass),
    section_id bigint NOT NULL,
    
    info_block_type_id bigint NOT NULL,  -- тип інформаційного блока (текст, картинка, файл, ...)
    style_id bigint,  -- стиль показу інфо блока
    
    "position" bigint, -- позиція в списку інфо блоків Розділа
    name character varying(255) COLLATE pg_catalog."default",
    descr character varying(255) COLLATE pg_catalog."default",
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_created character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    user_modified character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),

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
