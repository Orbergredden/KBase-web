# Роблю структуру даних для Розділів
```sql
kbase.sections
    id bigint NOT NULL DEFAULT nextval('kbase.seq_sections'::regclass),
    parent_id bigint,
    name character varying(255) COLLATE pg_catalog."default",
    descr character varying(255) COLLATE pg_catalog."default",
    type_id bigint NOT NULL DEFAULT 1, -- -- тип інформації розділу : 1 - документ, 2 - словник, в перспективі Галерея
    show_level int default 0,    -- 0 - приватний, 1 - для зареєстрованих користувачів, 2 - публічний
    category_id bigint NOT NULL, -- категорія розділу (наприклад Заявки, Роботи, Документація)
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_created character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    user_modified character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    date_modified_info timestamp without time zone    -- остання зміна інфоблоків
``` 
```sql
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
```
```sql
kbase.info_block_type  -- типи інфоблоків
    id bigint NOT NULL,
    name character varying(25) COLLATE pg_catalog."default",
    descr character varying(100) COLLATE pg_catalog."default",
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_created character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    user_modified character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
```
Такі типи інфо блоків для початку : текст, картинка, файл
```sql
kbase.info_block_type_components  -- компоненти з яких складається тип інфо блоку
    id bigint NOT NULL,
    info_block_type bigint NOT NULL,
    name character varying(25) COLLATE pg_catalog."default",
    descr character varying(100) COLLATE pg_catalog."default",
    info_block_component_type_id int NOT NULL,  -- 1 - текст, 2 - картинка, 3 - файл, 4 - ціле число, 5 - логічне значення
    date_created timestamp without time zone DEFAULT now(),
    date_modified timestamp without time zone DEFAULT now(),
    user_created character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
    user_modified character varying(30) COLLATE pg_catalog."default" DEFAULT "current_user"(),
```
```text
Такі компоненти :  
    Текст :  
        title - текст  
        text - текст  
        is_show_title - логічне  
    Картинка :   
        title - 1  
        image - 2  
        width - 4  
        height - 4  
        descr - 1  
        text - 1  
        is_show_title - 5  
        is_show_descr - 5  
        is_show_text  - 5  
    Файл :  
        title - 1  
        file_body - 3   
        file_name - 1  
        --icon_id -- на майбутнє  
        descr - 1  
        text - 1  
        is_show_title - 5  
        is_show_descr - 5  
        is_show_text  - 5  
```

```sql
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
```