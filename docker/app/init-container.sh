#!/bin/bash
set -e

# 📜 Historial persistente
export HISTFILE=~/.bash_history
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
touch "$HISTFILE"

echo "🔧 Configurando directorios y entorno inicial..."

APP_DIR="/app/code/api"
COMPOSER_HOME="/home/developer/.composer"
NPM_CONFIG_PREFIX="/home/developer/.npm-global"

VENDOR_DIR="$APP_DIR/vendor"
NODE_MODULES_DIR="$APP_DIR/node_modules"

# 🗂️ Crear directorios de entorno del usuario
mkdir -p "$APP_DIR" "$COMPOSER_HOME" "$NPM_CONFIG_PREFIX"

echo -e "\n🚀 Iniciando entorno de aplicación Laravel 🐘\n"

# 🆕 Si no hay proyecto Laravel, lo crea
if [ ! -f "$APP_DIR/artisan" ] && [ ! -f "$APP_DIR/composer.json" ]; then
    echo "📦 Instalando nuevo proyecto Laravel..."
    cd "$APP_DIR"
    find . -maxdepth 1 ! -name node_modules ! -name vendor ! -name . -exec rm -rf {} +
    composer create-project --prefer-dist laravel/laravel .

    [ -d "/tmp/vendor" ] && mv /tmp/vendor vendor
    [ -d "/tmp/node_modules" ] && mv /tmp/node_modules node_modules

    mkdir -p storage bootstrap/cache
    chmod -R 775 storage bootstrap/cache
fi

cd "$APP_DIR"

# ⚙️ Configuración de entorno
if [ ! -f ".env" ]; then
    echo "⚙️ Creando archivo .env..."
    cp .env.example .env
    php artisan key:generate || echo "⚠️ No se pudo generar la clave de app, verifica que Artisan esté disponible."
fi

# 📦 Instalación condicional de dependencias PHP
if [ ! -d "$VENDOR_DIR" ] || [ composer.lock -nt "$VENDOR_DIR" ]; then
    echo "📦 Ejecutando 'composer install'..."
    composer install --no-interaction --prefer-dist
else
    echo "✅ Dependencias PHP actualizadas."
fi

# 📦 Instalación condicional de dependencias Node.js
if [ ! -d "$NODE_MODULES_DIR" ] || [ -f yarn.lock -a yarn.lock -nt "$NODE_MODULES_DIR" ] || [ -f package-lock.json -a package-lock.json -nt "$NODE_MODULES_DIR" ]; then
    if [ -f yarn.lock ]; then
        echo "📦 Ejecutando 'yarn install'..."
        yarn install --frozen-lockfile
    else
        echo "📦 Ejecutando 'npm install'..."
        npm install
    fi
else
    echo "✅ Dependencias Node.js actualizadas."
fi

# 🔐 Permisos finales (modo seguro)
echo "🔐 Ajustando permisos finales..."

safe_chmod() {
    [ -e "$1" ] && [ -w "$1" ] && chmod -R 775 "$1" || echo "⚠️ Sin permisos para modificar $1"
}

find . -type d -exec chmod 775 {} \; || true
find . -type f -exec chmod 664 {} \; || true

safe_chmod "$APP_DIR/storage"
safe_chmod "$APP_DIR/bootstrap/cache"
safe_chmod "$VENDOR_DIR"
safe_chmod "$NODE_MODULES_DIR"

# Asegura que supervisord pueda escribir
mkdir -p /home/developer/supervisor
touch /home/developer/supervisor/nginx.pid
touch /home/developer/supervisor/nginx.access.log
touch /home/developer/supervisor/nginx.error.log

chmod -R 775 /home/developer/supervisor

echo -e "\n✅ Configuración completa. ¡Listo para trabajar! 🛠️\n"

# Ejecuta el CMD declarado en el Dockerfile
exec "$@"
