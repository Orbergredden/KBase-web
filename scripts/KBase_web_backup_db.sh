#!/bin/bash

# Параметри підключення до PostgreSQL
DB_USER="postgres"
DB_NAME="kbase_web_dev"
DB_HOST="localhost"
DB_PORT="5432"
export PGPASSWORD="postgres"

# Папка для збереження бекапів
BACKUP_DIR="/home/igor/_backup/_prog/KBase-web/_db-postgres"

# Створення папки для бекапів, якщо вона не існує
mkdir -p "$BACKUP_DIR"

# Форматування дати та часу (наприклад: "2026-07-05 11:03:20")
# Оскільки пробіли та двокрапки в іменах файлів допустимі в Linux, використовуємо саме такий формат.
# Якщо захочете замінити пробіли/двокрапки на більш безпечні символи, скористайтеся форматом: "%Y-%m-%d_%H-%M-%S"
BACKUP_DATE=$(date "+%Y-%m-%d_%H:%M:%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${BACKUP_DATE}.sql"

echo "=== Початок створення бекапу бази даних: $DB_NAME ==="
echo "Шлях до файлу: $BACKUP_FILE"

# Запуск утиліти pg_dump для створення бекапу у форматі звичайного SQL
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -Fp -f "$BACKUP_FILE"

# Перевірка статусу виконання команди
if [ $? -eq 0 ]; then
    echo "Бекап успішно створено: $BACKUP_FILE"
else
    echo "Помилка при створенні бекапу!" >&2
    exit 1
fi

# Архівування в zip
ZIP_FILE="$BACKUP_DIR/${DB_NAME}_${BACKUP_DATE}.zip"
echo "Архівування у формат ZIP..."
zip -j "$ZIP_FILE" "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "Архів створено успішно: $ZIP_FILE"
    echo "Видалення оригінального SQL-файлу..."
    rm "$BACKUP_FILE"
else
    echo "Помилка при архівуванні в zip!" >&2
    exit 1
fi

# Очищення змінної пароля для безпеки
unset PGPASSWORD
