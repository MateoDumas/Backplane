# Arquitectura de Microservicios

Este proyecto demuestra una arquitectura básica de microservicios usando Node.js, Express y Docker.

## Servicios

1.  **API Gateway** (Puerto 8080): Punto de entrada único. Enruta peticiones a los servicios correspondientes.
2.  **Auth Service** (Puerto 3000): Maneja autenticación (Login/Verificación de token).
3.  **Payment Service** (Puerto 3001): Procesa pagos.
4.  **Notification Service** (Puerto 3002): Envía notificaciones.
5.  **Frontend** (Puerto 3003): Dashboard web para interactuar con los servicios.

## Cómo ejecutar

### Opción A: Con Docker (Recomendado)
Esta opción **no requiere** instalar Node.js ni PostgreSQL manualmente. Docker se encarga de todo (incluyendo la base de datos).

Si tienes Docker instalado:
```bash
docker-compose up --build
```

Una vez iniciado, abre tu navegador en: **http://localhost:3003**

### 🐵 Chaos Mode (Ingeniería del Caos)
Hemos añadido un panel especial en el Frontend para simular fallos y aprender sobre resiliencia:
1.  **Auth Lento (Latencia):** Simula que la base de datos tarda 2 segundos en responder. Útil para ver cómo el frontend maneja las esperas.
2.  **Pagos Inestables (Errores):** Simula que el servicio de pagos falla aleatoriamente (Error 500) el 70% de las veces. Útil para probar reintentos (si los implementamos) o manejo de errores en UI.

### Opción B: Ejecución Local (Sin Docker)
Requiere tener instalados:
- Node.js
- PostgreSQL

#### 1. Configuración de Base de Datos
1. Crea una base de datos en PostgreSQL llamada `auth_db`.
2. Configura las credenciales en `auth-service/.env`.

#### 2. Ejecución
1.  **Instalar dependencias** en cada carpeta (`api-gateway`, `auth-service`, `payment-service`, `notification-service`):
    ```bash
    npm install
    ```
2.  **Configurar entorno**: Asegúrate de que `api-gateway/.env` apunte a `localhost`:
    ```env
    AUTH_SERVICE_URL=http://localhost:3000
    PAYMENT_SERVICE_URL=http://localhost:3001
    NOTIFICATION_SERVICE_URL=http://localhost:3002
    ```
3.  **Iniciar servicios**: Abre 4 terminales y ejecuta `npm start` en cada carpeta de servicio.

## Endpoints de prueba

-   **Login**:
    -   POST `http://localhost:8080/auth/login`
    -   Body: `{ "username": "admin", "password": "password" }`
-   **Pagos**:
    -   POST `http://localhost:8080/payments/process`
    -   Body: `{ "amount": 100, "currency": "USD" }`
-   **Notificaciones**:
    -   POST `http://localhost:8080/notifications/send`
    -   Body: `{ "to": "user@example.com", "message": "Hello" }`
