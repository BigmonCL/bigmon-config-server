package com.bigmon.configserver;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class BigmonConfigServerApplicationTests {

    @Test
    void contextLoads() {
        // Test básico para verificar que el contexto de Spring se carga correctamente
        // Al usar @ActiveProfiles("local") evitamos problemas con configuración Git en CI
    }

    @Test
    void applicationStartup() {
        // Verificar que la aplicación puede inicializar sin errores
        // Este test implícitamente verifica la configuración básica
    }
}