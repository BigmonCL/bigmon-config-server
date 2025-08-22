package com.bigmon.configserver.health;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketTimeoutException;

@Component
public class GitHealthIndicator implements HealthIndicator {

    @Value("${spring.cloud.config.server.git.uri:}")
    private String gitUri;

    @Value("${spring.cloud.config.server.git.timeout:5}")
    private int timeout;

    @Override
    public Health health() {
        try {
            if (gitUri.isEmpty()) {
                return Health.down()
                    .withDetail("status", "Git URI not configured")
                    .withDetail("uri", "empty")
                    .build();
            }

            // Extraer host del URI Git
            String host = extractHost(gitUri);
            if (host == null) {
                return Health.down()
                    .withDetail("status", "Invalid Git URI format")
                    .withDetail("uri", gitUri)
                    .build();
            }

            // Verificar conectividad SSH a GitHub/GitLab
            boolean isReachable = checkSSHConnectivity(host, 22);
            
            if (isReachable) {
                return Health.up()
                    .withDetail("status", "Git repository accessible")
                    .withDetail("uri", gitUri)
                    .withDetail("host", host)
                    .withDetail("timeout", timeout + "s")
                    .build();
            } else {
                return Health.down()
                    .withDetail("status", "Git repository not accessible")
                    .withDetail("uri", gitUri)
                    .withDetail("host", host)
                    .withDetail("error", "SSH connection failed")
                    .build();
            }

        } catch (Exception e) {
            return Health.down()
                .withDetail("status", "Git health check failed")
                .withDetail("error", e.getMessage())
                .withDetail("uri", gitUri)
                .build();
        }
    }

    private String extractHost(String gitUri) {
        try {
            if (gitUri.startsWith("git@")) {
                // Format: git@github.com:user/repo.git
                String[] parts = gitUri.split(":");
                if (parts.length >= 2) {
                    return parts[0].substring(4); // Remove "git@"
                }
            } else if (gitUri.startsWith("https://")) {
                // Format: https://github.com/user/repo.git
                return gitUri.split("/")[2];
            }
            return null;
        } catch (Exception e) {
            return null;
        }
    }

    private boolean checkSSHConnectivity(String host, int port) {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(host, port), timeout * 1000);
            return true;
        } catch (SocketTimeoutException e) {
            return false;
        } catch (IOException e) {
            return false;
        }
    }
}