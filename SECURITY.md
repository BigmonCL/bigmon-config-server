# Guía de Seguridad - Config Server

## 🚨 ACCIÓN INMEDIATA REQUERIDA

### Clave SSH Comprometida

La clave SSH que estaba en el código ha sido **COMPROMETIDA** y debe ser revocada inmediatamente.

#### Pasos Urgentes:

1. **Revocar clave actual en GitHub**:
   - Ir a: GitHub → Settings → Deploy keys
   - Eliminar la clave asociada al repositorio `bigmon-config-repo`

2. **Generar nueva clave SSH**:
```bash
# Generar nueva clave
ssh-keygen -t rsa -b 4096 -C "config-server@bigmon.cl" -f ~/.ssh/bigmon_config_new

# Verificar permisos correctos
chmod 600 ~/.ssh/bigmon_config_new
chmod 644 ~/.ssh/bigmon_config_new.pub
```

3. **Agregar nueva clave a GitHub**:
```bash
# Mostrar clave pública
cat ~/.ssh/bigmon_config_new.pub

# Agregar en: GitHub → Repository → Settings → Deploy keys
# Marcar como "Allow write access" solo si es necesario
```

4. **Actualizar configuración**:
```bash
# Configurar variable de entorno
export GIT_PRIVATE_KEY="$(cat ~/.ssh/bigmon_config_new)"
```

## 🛡️ Mejores Prácticas de Seguridad

### Gestión de Claves SSH

1. **Nunca** hardcodear claves en código
2. Usar variables de entorno o sistemas de secrets
3. Rotar claves regularmente (cada 6 meses)
4. Usar claves específicas por servicio
5. Monitorear accesos a repositorios

### Variables de Entorno Seguras

```bash
# ✅ CORRECTO - Variables de entorno
export GIT_PRIVATE_KEY="$(cat /secure/path/ssh_key)"

# ❌ INCORRECTO - Hardcodeado en archivo
private-key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  clave_aqui
  -----END OPENSSH PRIVATE KEY-----
```

### Variables de Entorno en Servidor

```bash
# Crear directorio seguro para variables
sudo mkdir -p /opt/bigmon-config-server/config
sudo chmod 750 /opt/bigmon-config-server/config

# Crear archivo de configuración
sudo tee /opt/bigmon-config-server/config/application.env > /dev/null <<EOF
SPRING_PROFILES_ACTIVE=prod
GIT_REPO_URI=git@github.com:BigmonCL/bigmon-config-repo.git
GIT_PRIVATE_KEY="$(cat /secure/path/ssh_key)"
EOF

# Configurar permisos seguros
sudo chown bigmon-config:bigmon-config /opt/bigmon-config-server/config/application.env
sudo chmod 640 /opt/bigmon-config-server/config/application.env
```

### SystemD Environment File

```bash
# Configuración segura con systemd
# Archivo: /opt/bigmon-config-server/config/application.env

# Configurar permisos restrictivos
sudo chmod 640 /opt/bigmon-config-server/config/application.env
sudo chown bigmon-config:bigmon-config /opt/bigmon-config-server/config/application.env

# El servicio systemd carga automáticamente las variables
# EnvironmentFile=/opt/bigmon-config-server/config/application.env
```

## 🔍 Auditoría y Monitoreo

### Logs de Seguridad

Monitor para estos eventos:
- Fallos de autenticación Git
- Intentos de acceso no autorizados
- Cambios en configuración de repositorio
- Health check failures relacionados con Git

### Alertas Recomendadas

```yaml
# Ejemplo de configuración de alertas (Prometheus/Grafana)
- alert: GitAccessFailed
  expr: up{job="config-server"} == 0
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "Config Server cannot access Git repository"

- alert: HealthCheckFailing
  expr: spring_boot_actuator_health_status{status!="UP"} == 1
  for: 1m
  labels:
    severity: warning
```

## 🔐 Configuración de Red

### Firewall Rules

```bash
# Solo permitir conexiones SSH salientes a GitHub/GitLab
iptables -A OUTPUT -p tcp --dport 22 -d github.com -j ACCEPT
iptables -A OUTPUT -p tcp --dport 22 -d gitlab.com -j ACCEPT
# Bloquear otras conexiones SSH salientes
iptables -A OUTPUT -p tcp --dport 22 -j DROP
```

### Proxy Configuration

```yaml
# Para entornos con proxy
spring:
  cloud:
    config:
      server:
        git:
          proxy:
            http:
              host: proxy.company.com
              port: 8080
            https:
              host: proxy.company.com
              port: 8080
```

## 📋 Checklist de Seguridad Pre-Producción

### Configuración
- [ ] Claves SSH no están en código fuente
- [ ] Variables de entorno configuradas correctamente
- [ ] Profiles de producción activados
- [ ] Timeouts apropiados configurados

### Acceso
- [ ] Clave SSH específica para config server
- [ ] Permisos mínimos en repositorio Git
- [ ] Deploy key configurada (no clave personal)
- [ ] Write access solo si es necesario

### Monitoreo
- [ ] Health checks funcionando
- [ ] Logs configurados apropiadamente
- [ ] Alertas de seguridad activas
- [ ] Dashboard de monitoreo configurado

### Red
- [ ] Firewall rules configuradas
- [ ] Proxy settings si aplica
- [ ] SSL/TLS configurado para endpoints públicos
- [ ] Rate limiting configurado

## 🚨 Procedimiento de Respuesta a Incidentes

### En caso de compromiso de clave:

1. **Inmediato** (0-15 minutos):
   - Revocar clave comprometida en GitHub
   - Detener servicios que usen la clave
   - Alertar al equipo de seguridad

2. **Corto plazo** (15-60 minutos):
   - Generar nueva clave SSH
   - Actualizar configuración con nueva clave
   - Reiniciar servicios
   - Verificar logs de acceso

3. **Seguimiento** (1-24 horas):
   - Auditar accesos al repositorio
   - Revisar configuraciones comprometidas
   - Actualizar documentación
   - Post-mortem del incidente

## 📞 Contactos de Emergencia

- **Equipo DevOps**: devops@bigmon.cl
- **Seguridad**: security@bigmon.cl
- **GitHub Admin**: admin@bigmon.cl