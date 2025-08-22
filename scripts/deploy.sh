#!/bin/bash

# Script de despliegue seguro para Config Server
# Uso: ./scripts/deploy.sh [dev|prod|local]

set -e  # Salir si cualquier comando falla

PROFILE=${1:-prod}
PROJECT_NAME="bigmon-config-server"

echo "🚀 Iniciando despliegue de $PROJECT_NAME en perfil: $PROFILE"

# Verificar que estamos en el directorio correcto
if [ ! -f "pom.xml" ]; then
    echo "❌ Error: Ejecutar desde el directorio raíz del proyecto"
    exit 1
fi

# Verificar variables de entorno requeridas
if [ "$PROFILE" != "local" ]; then
    if [ -z "$GIT_PRIVATE_KEY" ]; then
        echo "❌ Error: Variable GIT_PRIVATE_KEY no configurada"
        echo "Configurar con: export GIT_PRIVATE_KEY=\"\$(cat /path/to/ssh/key)\""
        exit 1
    fi
    
    if [ -z "$GIT_REPO_URI" ]; then
        echo "⚠️  Advertencia: GIT_REPO_URI no configurada, usando valor por defecto"
    fi
fi

# Función para verificar conectividad SSH
check_ssh_connectivity() {
    echo "🔍 Verificando conectividad SSH a GitHub..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "✅ Conectividad SSH verificada"
        return 0
    else
        echo "❌ Error: No se puede conectar a GitHub via SSH"
        echo "Verificar:"
        echo "1. Clave SSH configurada: ssh-add -l"
        echo "2. Acceso a GitHub: ssh -T git@github.com"
        return 1
    fi
}

# Función para construir la aplicación
build_application() {
    echo "🔨 Construyendo aplicación..."
    ./mvnw clean package -DskipTests
    
    if [ $? -eq 0 ]; then
        echo "✅ Construcción exitosa"
    else
        echo "❌ Error en construcción"
        exit 1
    fi
}

# Función para ejecutar tests
run_tests() {
    echo "🧪 Ejecutando tests..."
    ./mvnw test
    
    if [ $? -eq 0 ]; then
        echo "✅ Tests pasaron"
    else
        echo "❌ Tests fallaron"
        exit 1
    fi
}

# Función para despliegue local
deploy_local() {
    echo "🏠 Desplegando localmente..."
    export SPRING_PROFILES_ACTIVE=local
    ./mvnw spring-boot:run &
    
    # Esperar a que el servicio esté disponible
    echo "⏳ Esperando que el servicio esté disponible..."
    sleep 30
    
    # Verificar health check
    if curl -f http://localhost:8888/actuator/health > /dev/null 2>&1; then
        echo "✅ Servicio disponible en http://localhost:8888"
        echo "📊 Health check: http://localhost:8888/actuator/health"
    else
        echo "❌ Servicio no está disponible"
        exit 1
    fi
}

# Función para despliegue directo
deploy_jar() {
    echo "☕ Ejecutando JAR directamente..."
    
    # Configurar variables de entorno
    export SPRING_PROFILES_ACTIVE=$PROFILE
    export SERVER_PORT=8888
    
    # Ejecutar JAR en background
    nohup java -jar target/bigmon-config-server-*.jar > nohup.out 2>&1 &
    JAR_PID=$!
    echo $JAR_PID > app.pid
    
    # Esperar y verificar
    echo "⏳ Esperando que la aplicación esté lista..."
    sleep 30
    
    if kill -0 $JAR_PID 2>/dev/null; then
        echo "✅ Aplicación ejecutándose (PID: $JAR_PID)"
        
        # Verificar health check
        if curl -f http://localhost:8888/actuator/health > /dev/null 2>&1; then
            echo "✅ Health check exitoso"
            echo "📊 Servicios disponibles:"
            echo "   - Health: http://localhost:8888/actuator/health"
            echo "   - Info: http://localhost:8888/actuator/info"
        else
            echo "❌ Health check falló"
            echo "📋 Logs de la aplicación:"
            tail -50 nohup.out
            exit 1
        fi
    else
        echo "❌ Error al iniciar aplicación"
        cat nohup.out
        exit 1
    fi
}

# Función principal
main() {
    case $PROFILE in
        "local")
            echo "🏠 Modo local - sin verificación SSH"
            build_application
            run_tests
            deploy_local
            ;;
        "dev")
            echo "🔧 Modo desarrollo"
            check_ssh_connectivity
            build_application
            run_tests
            deploy_jar
            ;;
        "prod")
            echo "🏭 Modo producción"
            check_ssh_connectivity
            build_application
            run_tests
            deploy_jar
            ;;
        *)
            echo "❌ Perfil inválido: $PROFILE"
            echo "Uso: $0 [dev|prod|local]"
            exit 1
            ;;
    esac
}

# Función de limpieza
cleanup() {
    echo "🧹 Limpiando recursos temporales..."
    if [ "$PROFILE" = "local" ]; then
        pkill -f "spring-boot:run" 2>/dev/null || true
    elif [ -f "app.pid" ]; then
        PID=$(cat app.pid)
        kill $PID 2>/dev/null || true
        rm -f app.pid nohup.out
    fi
}

# Configurar trap para limpieza
trap cleanup EXIT

# Ejecutar función principal
main

echo "🎉 Despliegue completado exitosamente para perfil: $PROFILE"