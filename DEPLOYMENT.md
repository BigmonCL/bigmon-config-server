# Guía de Despliegue - Config Server

## 🔄 Proceso de CI/CD Actual

### Flujo de Trabajo

1. **Push a `main`** → Activa pipeline automático
2. **Tests** → Verificación de calidad
3. **Security Scan** → Análisis de vulnerabilidades  
4. **Build** → Construcción de JAR
5. **Deploy** → Despliegue automático al servidor
6. **Health Check** → Verificación post-despliegue

### Architecture del Pipeline

```mermaid
graph LR
    A[Push to main] --> B[Run Tests]
    B --> C[Security Scan]  
    C --> D[Build JAR]
    D --> E[SSH Deploy]
    E --> F[Restart Service]
    F --> G[Health Check]
```

## 🖥️ Configuración del Servidor

### Estructura de Directorios

```
/opt/bigmon-config-server/
├── bigmon-config-server.jar    # JAR principal
├── config/
│   └── application.env         # Variables de entorno
├── .ssh/
│   ├── id_rsa                 # Clave SSH para Git
│   └── config                 # Configuración SSH
├── logs/
│   └── bigmon-config-server.log
└── backups/
    ├── bigmon-config-server-backup-20250122-143022.jar
    └── ...
```

### Usuario del Sistema

- **Usuario**: `bigmon-config`
- **Grupo**: `bigmon-config`  
- **Home**: `/opt/bigmon-config-server`
- **Shell**: `/bin/false` (security)

## 🔧 Configuración SystemD

### Servicio: `bigmon-config-server.service`

**Ubicación**: `/etc/systemd/system/bigmon-config-server.service`

**Características**:
- ✅ Auto-restart en caso de falla
- 🔒 Configuración de seguridad hardened
- 📊 Logging a systemd journal
- 💾 Límites de recursos (1GB RAM max)
- 🏥 Health check post-inicio

### Comandos de Administración

```bash
# Estado del servicio
sudo systemctl status bigmon-config-server

# Iniciar/Parar/Reiniciar
sudo systemctl start bigmon-config-server
sudo systemctl stop bigmon-config-server  
sudo systemctl restart bigmon-config-server

# Habilitar/Deshabilitar auto-inicio
sudo systemctl enable bigmon-config-server
sudo systemctl disable bigmon-config-server

# Logs
sudo journalctl -u bigmon-config-server -f
sudo journalctl -u bigmon-config-server --since "1 hour ago"
```

## 🔐 Configuración de Seguridad

### SSH Keys

1. **Clave de Deploy** (`SSH_PRIVATE_KEY_BIGMON`)
   - Para conectar GitHub Actions → Servidor
   - Almacenada en GitHub Secrets

2. **Clave Git** (`GIT_PRIVATE_KEY`)  
   - Para acceder al repositorio de configuraciones
   - Almacenada en GitHub Secrets y servidor

### Variables de Entorno Seguras

**Archivo**: `/opt/bigmon-config-server/config/application.env`

```bash
SPRING_PROFILES_ACTIVE=prod
GIT_REPO_URI=git@github.com:BigmonCL/bigmon-config-repo.git
GIT_DEFAULT_BRANCH=main
GIT_IGNORE_LOCAL_SSH=false
GIT_CLONE_ON_START=false
GIT_TIMEOUT=5
JAVA_OPTS=-Xmx512m -Xms256m -XX:+UseG1GC -XX:MaxGCPauseMillis=100
```

## 🏥 Health Checks y Monitoreo

### Endpoints Disponibles

| Endpoint | Descripción | Ejemplo |
|----------|-------------|---------|
| `/actuator/health` | Estado general | `{"status":"UP"}` |
| `/actuator/health/liveness` | Liveness probe | Para health checks |
| `/actuator/health/readiness` | Readiness probe | Para health checks |
| `/actuator/info` | Info de aplicación | Versión, Git commit |
| `/actuator/metrics` | Métricas JVM | CPU, memoria, etc |

### Monitoreo en Producción

```bash
# Health check básico
curl http://localhost:8888/actuator/health

# Health check detallado (con jq)
curl -s http://localhost:8888/actuator/health | jq '.'

# Verificar conectividad Git específicamente
curl -s http://localhost:8888/actuator/health | jq '.components.git'

# Ver métricas de memoria
curl -s http://localhost:8888/actuator/metrics/jvm.memory.used | jq '.'
```

## 🚨 Procedimientos de Emergencia

### Rollback Rápido

```bash
# 1. Parar servicio actual
sudo systemctl stop bigmon-config-server

# 2. Restaurar JAR anterior
sudo cp /opt/bigmon-config-server/backups/bigmon-config-server-backup-YYYYMMDD-HHMMSS.jar \
       /opt/bigmon-config-server/bigmon-config-server.jar

# 3. Reiniciar servicio
sudo systemctl start bigmon-config-server

# 4. Verificar
curl http://localhost:8888/actuator/health
```

### Despliegue Manual (Emergency)

```bash
# En caso de falla del CI/CD
scp target/bigmon-config-server-*.jar user@server:/opt/bigmon-config-server/
ssh user@server "sudo systemctl restart bigmon-config-server"
```

### Logs de Troubleshooting

```bash
# Logs de la aplicación
sudo journalctl -u bigmon-config-server --no-pager -n 100

# Logs del sistema durante el deploy
sudo journalctl --since "30 minutes ago" | grep -i bigmon

# Logs de SSH (si hay problemas de Git)
sudo journalctl --since "30 minutes ago" | grep -i ssh

# Verificar espacio en disco
df -h /opt/bigmon-config-server/
```

## 📋 Checklist Pre-Producción

### Servidor
- [ ] Usuario `bigmon-config` creado
- [ ] Directorio `/opt/bigmon-config-server` configurado
- [ ] Servicio systemd instalado y habilitado
- [ ] Firewall configurado (puerto 8888)
- [ ] Java 17 instalado
- [ ] curl y jq instalados

### GitHub
- [ ] Secrets configurados correctamente
- [ ] Clave SSH para deploy funciona
- [ ] Nueva clave Git agregada al repositorio
- [ ] Workflow habilitado

### Configuración
- [ ] Variables de entorno configuradas
- [ ] Clave SSH Git en servidor
- [ ] Health checks respondiendo
- [ ] Logs rotando correctamente

## 📞 Contactos de Soporte

- **DevOps**: devops@bigmon.cl
- **GitHub Actions**: Revisar logs en GitHub Actions tab
- **Servidor**: SSH logs en `/var/log/auth.log`