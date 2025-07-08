#!/bin/bash
set -e

echo "🚀 Iniciando servicios con Supervisor..."

# Verifica si supervisord.conf existe (seguridad mínima)
if [ ! -f /etc/supervisor/supervisord.conf ]; then
  echo "❌ Error: no se encontró el archivo /etc/supervisor/supervisord.conf"
  exit 1
fi

# Ejecutar supervisord directamente como proceso principal
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
