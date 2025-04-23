#!/bin/bash

# AksTis Backup Script

# Универсальный скрипт для бэкапа директорий

# Автор: AksTis
# https://akstis.su/

# Версия: 1.0
# Дата: 24 Апреля 2025
# Лицензия: Общественное достояние

# Настраиваемые переменные
BACKUP_NAME="your_backup_name"  # Название (nginx, letsencrypt и т.д.)
SOURCE_DIRS="your_source_dir1 your_source_dir2"  # Список директорий для бэкапа (через пробел)

# Единожды настраиваемые переменные
BACKUP_DIR="/home/$USER/backup/$BACKUP_NAME"  # Базовая директория для хранения бэкапов
TEMP_DIR="$BACKUP_DIR/temp"  # Временная папка

# ZIP_PASSWORD="your_secure_password"

# Создай файл с паролем
# echo "your_secure_password" > /home/$USER/.zip_password
# chmod 600 /home/$USER/.zip_password
ZIP_PASSWORD=$(cat /home/$USER/.zip_password)  # Пароль для ZIP-архива

DATE=$(date +%Y-%m-%d_%H.%M.%S)
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

info "Проверка и создание каталога бэкапа: $BACKUP_DIR"
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR" || error "Ошибка создания $BACKUP_DIR"
fi

info "Создание временного каталога: $TEMP_DIR"
mkdir -p "$TEMP_DIR" || error "Ошибка создания $TEMP_DIR"

info "Копирование директорий: $SOURCE_DIRS"
for dir in $SOURCE_DIRS; do
    [ -d "$dir" ] || error "Директория $dir не существует"
    sudo cp -r "$dir" "$TEMP_DIR/$(echo "$dir" | sed 's|^/||;s|/|-|g')" || error "Ошибка копирования $dir"
done

info "Изменение владельца временных файлов на текущего пользователя"
sudo chown -R $USER:$USER "$TEMP_DIR" || error "Ошибка изменения владельца $TEMP_DIR"

ARCHIVE_NAME="$BACKUP_DIR/$BACKUP_NAME-backup-$DATE.zip"
info "Упаковка в ZIP-архив: $ARCHIVE_NAME"
cd "$TEMP_DIR" && zip -r -P "$ZIP_PASSWORD" "$ARCHIVE_NAME" . >/dev/null || error "Ошибка создания архива $ARCHIVE_NAME"

info "Установка прав и владельца для архива: $ARCHIVE_NAME"
chmod 600 "$ARCHIVE_NAME" && chown $USER:$USER "$ARCHIVE_NAME" || error "Ошибка установки прав/владельца $ARCHIVE_NAME"

info "Удаление временного каталога: $TEMP_DIR"
rm -rf "$TEMP_DIR" || error "Ошибка удаления $TEMP_DIR"

info "Бэкап успешно создан: $ARCHIVE_NAME"
ls -lh "$ARCHIVE_NAME"

exit 0