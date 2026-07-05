#!/bin/bash

# Параметри підключення до локальної PostgreSQL
DB_USER="postgres"
DB_NAME="postgres"
DB_HOST="localhost"
DB_PORT="5432"

# Вкажіть пароль тут, щоб psql не запитував його інтерактивно
# (Для вашої локальної розробки це цілком безпечно й зручно)
export PGPASSWORD="postgres"

echo "=== Підключення до локальної бази даних PostgreSQL ==="
echo "Користувач: $DB_USER | База: $DB_NAME | Порт: $DB_PORT"
echo "Вхід у psql... (для виходу введіть \q)"
echo "------------------------------------------------------"

# Запуск локальної утиліти psql
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME

# Очищаємо змінну пароля після виходу для безпеки сесії терміналу
unset PGPASSWORD
