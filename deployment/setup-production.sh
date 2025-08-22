#!/bin/bash

# Script de configuración inicial para producción
# Ejecutar como root en el servidor de producción

set -e

SERVICE_NAME="bigmon-config-server"
SERVICE_USER="bigmon-config"
SERVICE_GROUP="bigmon-config"
INSTALL_DIR="/opt/bigmon-config-server"
CONFIG_DIR="$INSTALL_DIR/config"
LOGS_DIR="$INSTALL_DIR/logs"
SSH_DIR="$INSTALL_DIR/.ssh"
BACKUP_DIR="$INSTALL_DIR/backups"

echo "🚀 Configurando Config Server para producción..."

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Este script debe ejecutarse como root"
   exit 1
fi

# Crear usuario del servicio si no existe
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "👤 Creando usuario $SERVICE_USER..."
    useradd --system --home-dir "$INSTALL_DIR" --shell /bin/false "$SERVICE_USER"
    usermod -a -G "$SERVICE_GROUP" "$SERVICE_USER" 2>/dev/null || groupadd "$SERVICE_GROUP"
else
    echo "✅ Usuario $SERVICE_USER ya existe"
fi

# Crear estructura de directorios
echo "📁 Creando directorios..."
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$LOGS_DIR" "$SSH_DIR" "$BACKUP_DIR"

# Configurar permisos
echo "🔒 Configurando permisos..."
chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
chmod 755 "$INSTALL_DIR"
chmod 750 "$CONFIG_DIR" "$LOGS_DIR" "$BACKUP_DIR"
chmod 700 "$SSH_DIR"

# Crear archivo de configuración de entorno por defecto
echo "⚙️ Creando configuración por defecto..."
cat > "$CONFIG_DIR/application.env" <<EOF
# Configuración de Spring Boot Config Server
SPRING_PROFILES_ACTIVE=prod

# Configuración Git
GIT_REPO_URI=git@github.com:BigmonCL/bigmon-config-repo.git
GIT_DEFAULT_BRANCH=main
GIT_IGNORE_LOCAL_SSH=false
GIT_CLONE_ON_START=false
GIT_TIMEOUT=5

# Configuración JVM
JAVA_OPTS=-Xmx512m -Xms256m -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$LOGS_DIR/heapdump.hprof

# Configuración de logging
LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_CLOUD_CONFIG=INFO
LOGGING_LEVEL_ORG_ECLIPSE_JGIT=WARN
LOGGING_FILE_PATH=$LOGS_DIR/bigmon-config-server.log
EOF

chown "$SERVICE_USER:$SERVICE_GROUP" "$CONFIG_DIR/application.env"
chmod 640 "$CONFIG_DIR/application.env"

# Configurar SSH para GitHub
echo "🔑 Configurando SSH..."
cat > "$SSH_DIR/config" <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_DIR/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF

chown "$SERVICE_USER:$SERVICE_GROUP" "$SSH_DIR/config"
chmod 600 "$SSH_DIR/config"

# Instalar servicio systemd
echo "🔧 Instalando servicio systemd..."
cp "$(dirname "$0")/bigmon-config-server.service" "/etc/systemd/system/"
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

# Configurar logrotate
echo "📋 Configurando rotación de logs..."
cat > "/etc/logrotate.d/$SERVICE_NAME" <<EOF
$LOGS_DIR/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    su $SERVICE_USER $SERVICE_GROUP
}
EOF

# Configurar firewall (opcional)
if command -v ufw >/dev/null 2>&1; then
    echo "🔥 Configurando firewall..."
    ufw allow 8888/tcp comment "Bigmon Config Server"
fi

# Instalar dependencias si no existen
echo "📦 Verificando dependencias..."
if ! command -v java >/dev/null 2>&1; then
    echo "⚠️ Java no está instalado. Instalar OpenJDK 17:"
    echo "   Ubuntu/Debian: apt update && apt install -y openjdk-17-jdk"
    echo "   CentOS/RHEL: yum install -y java-17-openjdk"
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "⚠️ curl no está instalado. Instalar:"
    echo "   Ubuntu/Debian: apt install -y curl"
    echo "   CentOS/RHEL: yum install -y curl"
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "⚠️ jq no está instalado (recomendado para health checks):"
    echo "   Ubuntu/Debian: apt install -y jq"
    echo "   CentOS/RHEL: yum install -y jq"
fi

echo ""
echo "✅ Configuración completada!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Agregar la clave SSH privada: $SSH_DIR/id_rsa"
echo "2. Copiar el JAR de la aplicación: $INSTALL_DIR/bigmon-config-server.jar"
echo "3. Ajustar variables en: $CONFIG_DIR/application.env"
echo "4. Iniciar el servicio: systemctl start $SERVICE_NAME"
echo ""
echo "📊 Comandos útiles:"
echo "   Estado del servicio: systemctl status $SERVICE_NAME"
echo "   Ver logs: journalctl -u $SERVICE_NAME -f"
echo "   Health check: curl http://localhost:8888/actuator/health"
echo ""