# Bigmon Config Server

Servidor centralizado de configuración Spring Cloud Config para el ecosistema Bigmon.

## 🔒 Configuración Segura

### ⚠️ IMPORTANTE: Pasos de Seguridad Obligatorios

1. **Regenerar Clave SSH**: La clave anterior fue comprometida y debe ser regenerada
2. **Configurar Secrets en GitHub**: Usar GitHub Secrets para credenciales
3. **Configurar Servidor de Producción**: Setup inicial en servidor Linux

## 🚀 Despliegue con CI/CD (GitHub Actions)

### 1. Setup Inicial del Servidor

**En el servidor de producción (como root):**

```bash
# 1. Ejecutar script de configuración
chmod +x deployment/setup-production.sh
./deployment/setup-production.sh
```

### 2. Configurar GitHub Secrets

**En GitHub Repository → Settings → Secrets and variables → Actions:**

| Secret | Descripción | Valor |
|--------|-------------|--------|
| `SSH_PRIVATE_KEY_BIGMON` | Clave SSH para conectar al servidor | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `BIGMON_PROD_SERVER_IP` | IP del servidor de producción | `123.456.789.0` |
| `BIGMON_PROD_SERVER_USER` | Usuario SSH en servidor | `bigmon-deploy` |
| `GIT_PRIVATE_KEY` | Nueva clave SSH para GitHub | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

### 3. Generar Nueva Clave SSH para Git

```bash
# 1. Generar nueva clave SSH
ssh-keygen -t rsa -b 4096 -C "config-server@bigmon.cl" -f ~/.ssh/bigmon_config_new

# 2. Agregar clave pública a GitHub
cat ~/.ssh/bigmon_config_new.pub
# GitHub → Repository → Settings → Deploy keys → Add key

# 3. Agregar clave privada a GitHub Secrets
cat ~/.ssh/bigmon_config_new | pbcopy  # macOS
# Pegar en GitHub Secret: GIT_PRIVATE_KEY
```

### 4. Despliegue Automático

El despliegue se activa automáticamente cuando se hace push a `main`:

```bash
git add .
git commit -m "Deploy config server updates"
git push origin main
```

**Pipeline incluye:**
- ✅ Tests automatizados
- 🔍 Security scan
- 📦 Build de aplicación
- 🚀 Deploy al servidor
- 🏥 Health checks

### 5. Desarrollo Local

```bash
# 1. Configurar profile de desarrollo
export SPRING_PROFILES_ACTIVE=dev
export GIT_PRIVATE_KEY="$(cat ~/.ssh/bigmon_config_new)"

# 2. Ejecutar aplicación
./mvnw spring-boot:run
```

## 📊 Monitoreo y Operaciones

### Comandos Útiles en Servidor

```bash
# Estado del servicio
sudo systemctl status bigmon-config-server

# Ver logs en tiempo real
sudo journalctl -u bigmon-config-server -f

# Reiniciar servicio
sudo systemctl restart bigmon-config-server

# Health check manual
curl http://localhost:8888/actuator/health | jq '.'

# Ver métricas
curl http://localhost:8888/actuator/metrics

# Ver información de la aplicación
curl http://localhost:8888/actuator/info
```

### Troubleshooting

#### Error: "Could not clone remote repository"

```bash
# 1. Verificar clave SSH
sudo -u bigmon-config ssh -T git@github.com

# 2. Verificar configuración SSH
sudo cat /opt/bigmon-config-server/.ssh/config

# 3. Verificar permisos
sudo ls -la /opt/bigmon-config-server/.ssh/

# 4. Ver logs específicos de Git
sudo journalctl -u bigmon-config-server | grep -i git
```

#### Servicio no inicia

```bash
# 1. Verificar configuración systemd
sudo systemctl cat bigmon-config-server

# 2. Ver errores de inicio
sudo journalctl -u bigmon-config-server --no-pager -n 50

# 3. Verificar variables de entorno
sudo cat /opt/bigmon-config-server/config/application.env

# 4. Verificar permisos de archivos
sudo ls -la /opt/bigmon-config-server/
```

## 🔧 Configuración por Entorno

### Profiles Disponibles

- `dev`: Desarrollo (clone-on-start=true, debug logging)
- `prod`: Producción (optimizado, logging mínimo)
- `local`: Local sin Git (usa archivos locales)

### Variables de Entorno

| Variable | Descripción | Por Defecto |
|----------|-------------|-------------|
| `GIT_REPO_URI` | URI del repositorio Git | `git@github.com:BigmonCL/bigmon-config-repo.git` |
| `GIT_PRIVATE_KEY` | Clave SSH privada (requerida) | - |
| `GIT_DEFAULT_BRANCH` | Rama por defecto | `main` |
| `GIT_IGNORE_LOCAL_SSH` | Ignorar config SSH local | `false` |
| `GIT_CLONE_ON_START` | Clonar al inicio | `false` |
| `GIT_TIMEOUT` | Timeout Git (segundos) | `5` |
| `SPRING_PROFILES_ACTIVE` | Profile activo | `prod` |

## 📊 Monitoreo

### Endpoints Actuator

- `GET /actuator/health` - Estado general y conectividad Git
- `GET /actuator/info` - Información de la aplicación
- `GET /actuator/refresh` - Refrescar configuración
- `GET /actuator/env` - Variables de entorno (solo dev)

### Health Checks

El sistema incluye un health indicator personalizado que verifica:
- Conectividad SSH al servidor Git
- Formato válido del URI Git
- Timeouts configurados

## 🔍 Troubleshooting

### Error: "Could not clone remote repository"

1. Verificar clave SSH:
```bash
ssh -T git@github.com
```

2. Verificar variables de entorno:
```bash
curl http://localhost:8888/actuator/health
```

3. Verificar logs:
```bash
sudo journalctl -u bigmon-config-server -f
```

### Error: "Authentication failed"

- La clave SSH no está configurada correctamente
- La clave no tiene permisos en el repositorio
- El formato de la clave en la variable de entorno es incorrecto

### Error: "Connection timeout"

- Verificar conectividad de red al servidor Git
- Ajustar `GIT_TIMEOUT` si es necesario
- Revisar configuración de proxy si aplica

## 🚨 Checklist de Seguridad

- [ ] Clave SSH anterior eliminada de GitHub
- [ ] Nueva clave SSH generada y configurada
- [ ] Variables de entorno configuradas (no hardcodeadas)
- [ ] Historial Git limpiado
- [ ] Permisos mínimos en clave SSH (600)
- [ ] Health checks configurados
- [ ] Logging apropiado para el entorno
- [ ] Secrets management configurado en producción

## 📞 Soporte

Para problemas de conectividad Git o configuración, verificar:
1. Estado del health check: `curl /actuator/health`
2. Logs de la aplicación
3. Conectividad SSH manual
4. Variables de entorno