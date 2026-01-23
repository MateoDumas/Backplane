# 🚀 Backplane - Arquitectura de Microservicios Resiliente

![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)
![Node.js](https://img.shields.io/badge/Node.js-v18-green.svg?style=flat-square&logo=node.js)
![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg?style=flat-square&logo=docker)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791.svg?style=flat-square&logo=postgresql)
![Nginx](https://img.shields.io/badge/Nginx-Proxy-009639.svg?style=flat-square&logo=nginx)
![Status](https://img.shields.io/badge/Estado-Producción-success.svg?style=flat-square)

> **Una demostración de microservicios de nivel empresarial con patrones avanzados de resiliencia, ingeniería del caos y observabilidad completa.**

---

## 🌟 ¿Por qué este proyecto?

Este repositorio demuestra cómo construir **sistemas distribuidos robustos y tolerantes a fallos**. A diferencia de aplicaciones CRUD básicas, **Backplane** implementa patrones arquitectónicos críticos requeridos en entornos empresariales de alta escala:

*   🛡️ **Circuit Breaker (Cortocircuito)**: Previene fallos en cascada cuando un servicio dependiente está caído.
*   🚦 **Rate Limiting (Limitación de Tasa)**: Protege las APIs contra ataques DDoS y abusos.
*   🔁 **Idempotencia**: Asegura que las transacciones financieras se procesen exactamente una vez, incluso durante reintentos de red.
*   🐵 **Chaos Engineering (Ingeniería del Caos)**: Herramientas integradas para simular latencia, caídas y fallos aleatorios para probar la estabilidad del sistema.
*   ☁️ **Cloud Native**: Totalmente contenerizado con Docker y desplegado vía Render Blueprints (Infraestructura como Código).

---

## 🏗 Resumen de Arquitectura

El sistema está compuesto por microservicios desacoplados que se comunican vía APIs REST, orquestados por un Gateway central.

```mermaid
graph TD
    Client[🖥️ Frontend UI (Nginx)] -->|HTTPS| Gateway[🚪 API Gateway]
    
    subgraph "Red Interna (Docker/Render)"
        Gateway -->|Ruta /auth| Auth[🔐 Auth Service]
        Gateway -->|Ruta /payments| Payment[💰 Payment Service]
        Gateway -->|Ruta /notifications| Notif[📨 Notification Service]
        
        Auth -->|Lectura/Escritura| DB[(🗄️ PostgreSQL)]
        Payment -->|Lectura/Escritura| DB
    end
    
    classDef service fill:#f9f,stroke:#333,stroke-width:2px;
    classDef db fill:#ff9,stroke:#333,stroke-width:2px;
    class Auth,Payment,Notif,Gateway service;
    class DB db;
```

### 🧩 Desglose de Servicios

| Servicio | Stack | Responsabilidades |
|---------|-------|------------------|
| **Frontend** | Nginx, HTML5, Bootstrap | Dashboard Responsivo, Monitoreo de Salud, Panel de Control de Caos. |
| **API Gateway** | Node.js, Express, `http-proxy` | Enrutamiento, **Circuit Breaker**, **Rate Limiting**, Terminación SSL. |
| **Auth Service** | Node.js, JWT, `pg` | Gestión de Usuarios, Login Seguro, Generación de Tokens (JWT). |
| **Payment Service** | Node.js, PostgreSQL | Procesamiento de Transacciones, **Chequeos de Idempotencia**, Hooks de Simulación de Caos. |
| **Notification** | Node.js | Manejo de eventos asíncronos (simulación email/SMS). |
| **Database** | PostgreSQL 15 | Persistencia relacional para usuarios y transacciones financieras. |

---

## 🔥 Características de Ingeniería Clave

### 1. Patrones de Resiliencia
*   **Circuit Breaker (Opossum/Custom)**: Si el Servicio de Pagos falla 3 veces consecutivas, el Gateway "abre el circuito" por 10 segundos, fallando rápido (503) sin sobrecargar el servicio afectado.
*   **Exponential Backoff (Reintento Exponencial)**: El cliente frontend reintenta inteligentemente las peticiones fallidas con retrasos incrementales (1s, 2s, 4s...) para manejar cortes de red transitorios.
*   **Rate Limiting**: Limita a los clientes a 5 peticiones por cada 10 segundos para prevenir el agotamiento de recursos.

### 2. Implementación de Idempotencia
Crítico para aplicaciones fintech. Cada petición de pago lleva un encabezado único `Idempotency-Key`.
*   **Escenario**: Cliente envía pago -> Servidor procesa -> Red falla antes de que la respuesta llegue al cliente -> Cliente reintenta.
*   **Resultado**: El servidor detecta la Key repetida y devuelve la respuesta de éxito original *desde caché* en lugar de cobrar al usuario dos veces.

### 3. Suite de Ingeniería del Caos 💥
Un panel dedicado de "Chaos Monkey" en el frontend permite romper el sistema a propósito para verificar su resiliencia:
*   **Inyección de Latencia**: Agrega 2000ms de retraso a las peticiones del Servicio de Autenticación.
*   **Fallos Aleatorios**: Hace que el Servicio de Pagos falle el 70% de las veces.
*   **Modo Crash**: Simula una caída total (Service Unavailable) para disparar el Circuit Breaker.

---

## 🚀 Comenzando

### Prerrequisitos
*   [Docker Desktop](https://www.docker.com/products/docker-desktop)
*   Git

### Instalación Local (Docker Compose)
La forma más fácil de ejecutar el stack completo localmente:

```bash
# 1. Clonar el repositorio
git clone https://github.com/MateoDumas/Backplane.git
cd Backplane

# 2. Iniciar todos los servicios
docker-compose up -d --build
```

**Acceder a la aplicación:**
*   💻 **Dashboard**: [http://localhost:3003](http://localhost:3003)
*   🔌 **API Gateway**: [http://localhost:8080](http://localhost:8080)

---

## ☁️ Despliegue

Este proyecto está configurado para **Despliegue sin Tiempo de Inactividad (Zero-Downtime)** en [Render](https://render.com).

### Render Blueprint (Infraestructura como Código)
El archivo `render.yaml` define toda la infraestructura:
1.  **Base de Datos PostgreSQL** (Gestionada)
2.  **Servicios Web** (Auth, Payment, Notification, Gateway)
3.  **Sitio Estático** (Frontend vía contenedor Nginx)

Todos los servicios están conectados vía una red interna privada con descubrimiento DNS.

---

## 🧪 Pruebas y Verificación

### 1. Demo de Circuit Breaker
1.  Abre el panel **Chaos Monkey** en el Dashboard.
2.  Activa **"💀 MATAR Payment Service"**.
3.  Intenta procesar un pago.
4.  **Resultado**: Después de 3 fallos, verás la etiqueta `CIRCUIT OPEN`. El Gateway deja de reenviar peticiones inmediatamente.

### 2. Demo de Idempotencia
1.  Abre las DevTools del Navegador (Pestaña Network).
2.  Haz clic en "Procesar Pago".
3.  Copia la petición como cURL y ejecútala dos veces en tu terminal con la misma `Idempotency-Key`.
4.  **Resultado**: Ambas devuelven `200 OK`, pero solo se crea una entrada en la base de datos.

---

## 👨‍💻 Autor

**Mateo Dumas**  
*Ingeniero de Software Full Stack & Entusiasta de Sistemas Distribuidos*

*   💼 [LinkedIn](#)
*   🐙 [GitHub](https://github.com/MateoDumas)
*   📧 [Email](#)

---

*Hecho con ❤️ y Node.js*
