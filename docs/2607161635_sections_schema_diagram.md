# Database Schema Diagram

```mermaid
erDiagram
    %% ==================== CORE TABLES ====================
    SECTIONS {
        bigint id PK "PK, auto"
        bigint parent_id FK "FK → sections.id"
        varchar name "NOT NULL"
        varchar descr
        bigint type_id FK "FK → info_block_type.id"
        int show_level "0=private,1=reg,2=public"
        bigint category_id FK "FK → category.id"
        timestamp date_created
        timestamp date_modified
        varchar user_created "FK → users.id"
        varchar user_modified "FK → users.id"
        timestamp date_modified_info
    }

    INFO_BLOCK_HEADERS {
        bigint id PK "PK, auto"
        bigint section_id FK "FK → sections.id"
        bigint info_block_type_id FK "FK → info_block_type.id"
        bigint style_id FK "FK → info_block_style.id"
        bigint position "UNIQUE(section_id, position)"
        varchar name
        varchar descr
        timestamp date_created
        timestamp date_modified
        varchar user_created
        varchar user_modified
    }

    INFO_BLOCK_TYPE {
        bigint id PK
        varchar name "TEXT/IMAGE/FILE/GALLERY"
        varchar descr
        timestamp date_created
        timestamp date_modified
        varchar user_created
        varchar user_modified
    }

    %% ==================== REFERENCE TABLES ====================
    CATEGORY {
        bigint id PK
        varchar name
        bigint parent_id FK "FK → category.id"
    }

    INFO_BLOCK_STYLE {
        bigint id PK
        varchar code "UNIQUE"
        varchar name
        varchar css_class
    }

    INFO_BLOCK_COMPONENT_TYPE {
        int id PK "1=text,2=image,3=file,4=number,5=boolean"
        varchar code "UNIQUE"
        varchar name
        varchar value_table "target table name"
    }

    %% ==================== COMPONENT DEFINITIONS ====================
    INFO_BLOCK_TYPE_COMPONENTS {
        bigint id PK
        bigint info_block_type_id FK "FK → info_block_type.id"
        varchar name
        varchar descr
        int info_block_component_type_id FK "FK → info_block_component_type.id"
        timestamp date_created
        timestamp date_modified
        varchar user_created
        varchar user_modified
    }

    %% ==================== VALUE TABLES (EAV) ====================
    INFO_BLOCK_COMPONENTS_TEXT {
        bigint id PK "PK, auto"
        bigint info_block_header_id FK "FK → info_block_headers.id"
        bigint info_block_type_component_id FK "FK → info_block_type_components.id"
        text value
    }

    INFO_BLOCK_COMPONENTS_BINARY {
        bigint id PK "PK, auto"
        bigint info_block_header_id FK "FK → info_block_headers.id"
        bigint info_block_type_component_id FK "FK → info_block_type_components.id"
        bytea value
    }

    INFO_BLOCK_COMPONENTS_NUMBER {
        bigint id PK "PK, auto"
        bigint info_block_header_id FK "FK → info_block_headers.id"
        bigint info_block_type_component_id FK "FK → info_block_type_components.id"
        bigint value
    }

    %% ==================== RELATIONSHIPS ====================
    SECTIONS ||--o{ SECTIONS : "parent_id (self-ref)"
    SECTIONS }|--|| CATEGORY : "category_id"
    SECTIONS }|--|| INFO_BLOCK_TYPE : "type_id"
    
    SECTIONS ||--o{ INFO_BLOCK_HEADERS : "section_id"
    INFO_BLOCK_HEADERS }|--|| INFO_BLOCK_TYPE : "info_block_type_id"
    INFO_BLOCK_HEADERS }|--|| INFO_BLOCK_STYLE : "style_id"
    
    INFO_BLOCK_TYPE ||--o{ INFO_BLOCK_TYPE_COMPONENTS : "info_block_type_id"
    INFO_BLOCK_TYPE_COMPONENTS }|--|| INFO_BLOCK_COMPONENT_TYPE : "info_block_component_type_id"
    
    INFO_BLOCK_HEADERS ||--o{ INFO_BLOCK_COMPONENTS_TEXT : "info_block_header_id"
    INFO_BLOCK_HEADERS ||--o{ INFO_BLOCK_COMPONENTS_BINARY : "info_block_header_id"
    INFO_BLOCK_HEADERS ||--o{ INFO_BLOCK_COMPONENTS_NUMBER : "info_block_header_id"
    
    INFO_BLOCK_TYPE_COMPONENTS ||--o{ INFO_BLOCK_COMPONENTS_TEXT : "info_block_type_component_id"
    INFO_BLOCK_TYPE_COMPONENTS ||--o{ INFO_BLOCK_COMPONENTS_BINARY : "info_block_type_component_id"
    INFO_BLOCK_TYPE_COMPONENTS ||--o{ INFO_BLOCK_COMPONENTS_NUMBER : "info_block_type_component_id"
```

---

## Legend

| Symbol | Meaning |
|--------|---------|
| `||--o{` | One-to-Many (parent → children) |
| `}|--||` | Many-to-One (child → parent) |
| `PK` | Primary Key |
| `FK` | Foreign Key (logical, not yet created in DB) |
| `UNIQUE` | Unique constraint |

---

## Missing Tables (referenced but not defined)

| Table | Referenced by |
|-------|---------------|
| `category` | `sections.category_id` |
| `info_block_style` | `info_block_headers.style_id` |
| `info_block_component_type` | `info_block_type_components.info_block_component_type_id` |
| `users` | `sections.user_created`, `sections.user_modified`, etc. |

---

## Current Issues Visualized

```
┌─────────────────────────────────────────────────────────────┐
│  ❌ NO FK CONSTRAINTS EXIST IN CURRENT SCHEMA               │
│  ❌ DUPLICATE date_modified in SECTIONS (line 11 & 15)      │
│  ❌ EAV PATTERN: 3 separate value tables                    │
│  ❌ user_created/modified = varchar(30) not FK to users     │
│  ❌ No UNIQUE(section_id, position) on info_block_headers   │
└─────────────────────────────────────────────────────────────┘
```

---

## Recommended Refactored Structure (Concrete Tables)

```mermaid
erDiagram
    INFO_BLOCK_HEADERS ||--|| INFO_BLOCK_TEXT : "1:1 (type=TEXT)"
    INFO_BLOCK_HEADERS ||--|| INFO_BLOCK_IMAGE : "1:1 (type=IMAGE)"
    INFO_BLOCK_HEADERS ||--|| INFO_BLOCK_FILE : "1:1 (type=FILE)"
    
    INFO_BLOCK_TEXT {
        bigint info_block_header_id PK,FK
        text title
        text body
        boolean is_show_title
    }
    
    INFO_BLOCK_IMAGE {
        bigint info_block_header_id PK,FK
        text title
        bytea image
        int width
        int height
        text descr
        text alt_text
        boolean is_show_title
        boolean is_show_descr
        boolean is_show_alt
    }
    
    INFO_BLOCK_FILE {
        bigint info_block_header_id PK,FK
        text title
        bytea file_body
        text file_name
        text descr
        boolean is_show_title
        boolean is_show_descr
    }
```

> **Benefit**: Eliminates EAV, enables NOT IN complexity, allows proper constraints, indexes, and simple JOINs.