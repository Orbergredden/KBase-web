
- зробити другий create (flamingo)


Додай створення цих табличок і всього іншого для них в кінець файла kbase_update_1.00.00.003.sql
по аналогії з тими що вже є у цьому файлі

section_document_info_block_headers  -- заголовки інфо блоків Розділів
    id 
    section_id 
    section_document_info_block_type_id  -- тип інформаційного блока (текст, картинка, файл, ...)
    section_document_info_block_style_id   -- стиль показу інфо блока
    "position" bigint, -- позиція в списку інфо блоків Розділа
    name 
    descr
    date/user

section_document_info_block_components_text  -- тут зберігаються компоненти типів 1 - текст
    id 
    section_document_info_block_header_id
    section_document_info_block_type_component_id
    "value" text

section_document_info_block_components_binary  -- тут зберігаються компоненти типів 2 - картинка, 3 - файл
    id 
    section_document_info_block_header_id 
    section_document_info_block_type_component_id 
    "value" bytea

section_document_info_block_components_number  -- тут зберігаються компоненти типів 4 - ціле число, 5 - логічне значення
    id 
    section_document_info_block_header_id bigint NOT NULL,
    section_document_info_block_type_component_id bigint NOT NULL,  -- 
    "value" bigint
