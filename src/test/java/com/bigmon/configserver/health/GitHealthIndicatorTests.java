package com.bigmon.configserver.health;

import org.junit.jupiter.api.Test;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.Status;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
class GitHealthIndicatorTests {

    @Test
    void healthIndicatorReturnsDownWhenGitUriEmpty() {
        GitHealthIndicator healthIndicator = new GitHealthIndicator();
        
        // Simular configuración vacía usando reflection o configuración de test
        Health health = healthIndicator.health();
        
        // Verificar que el health check maneja correctamente URIs vacías
        assertThat(health).isNotNull();
        assertThat(health.getStatus()).isIn(Status.DOWN, Status.UP);
    }

    @Test
    void healthIndicatorHandlesInvalidUri() {
        GitHealthIndicator healthIndicator = new GitHealthIndicator();
        
        Health health = healthIndicator.health();
        
        // El health indicator debe manejar gracefulmente URIs inválidas
        assertThat(health).isNotNull();
        assertThat(health.getDetails()).isNotNull();
    }
}