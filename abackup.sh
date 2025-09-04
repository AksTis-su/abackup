#!/bin/bash
#
# AksTis Backup Script
#
# Универсальный скрипт для бэкапа директорий и файлов
#
# Автор: AksTis
# https://akstis.su/
#
# Версия: 1.0
# Дата: 24 Апреля 2025
# Лицензия: MIT

# Настраиваемые переменные
BACKUP_NAME="your_backup_name"  # Название (nginx, letsencrypt и т.д.)
SOURCE_PATHS="your_source_dir your/file.txt"  # Список директорий и файлов для бэкапа (через пробел)

# Единожды настраиваемые переменные
BACKUP_DIR="/home/$USER/backup/$BACKUP_NAME"  # Базовая директория для хранения бэкапов
TEMP_DIR="$BACKUP_DIR/temp"  # Временная папка

# ZIP_PASSWORD="your_secure_password"

# Создай файл с паролем
# echo "your_secure_password" > /home/$USER/.abackup_zip_pass
# chmod 600 /home/$USER/.abackup_zip_pass
ZIP_PASSWORD=$(cat /home/$USER/.abackup_zip_pass)  # Пароль для ZIP-архива

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

info "Копирование: $SOURCE_PATHS"
for path in $SOURCE_PATHS; do
	[ -e "$path" ] || error "Файл или директория $path не существует"
	dest_name=$(echo "$path" | sed 's|^/||;s|/|-|g')
	if [ -d "$path" ]; then
		sudo cp -r "$path" "$TEMP_DIR/$dest_name" || error "Ошибка копирования $path"
	else
		dest_dir="$TEMP_DIR/$(dirname "$path" | sed 's|^/||;s|/|-|g')"
		mkdir -p "$dest_dir" && sudo cp "$path" "$dest_dir/$(basename "$path")" || error "Ошибка копирования $path"
	fi
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
