# 🚀 Backplane - Microservices Architecture Demo

Production-ready microservices architecture showcasing resilience patterns, chaos engineering, and scalability using Node.js, Docker, and PostgreSQL.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Node.js](https://img.shields.io/badge/node.js-v18-green.svg)
![Docker](https://img.shields.io/badge/docker-compose-blue.svg)
![Status](https://img.shields.io/badge/status-stable-success.svg)

## 🏗 Architecture

The system consists of independent microservices orchestrated via Docker Compose and accessed through a unified API Gateway.

| Service | Port (Internal) | Description |
|---------|----------------|-------------|
| **Frontend** | 80 (Nginx) | Responsive UI for managing payments, auth, and monitoring system health. |
| **API Gateway** | 8080 | Entry point. Handles routing, **Rate Limiting**, and **Circuit Breaker** logic. |
| **Auth Service** | 3000 | JWT Authentication and user management. |
| **Payment Service** | 3001 | Payment processing with **PostgreSQL** persistence and **Idempotency**. |
| **Notification** | 3002 | Simulates email/SMS notifications on successful events. |
| **PostgreSQL** | 5432 | Primary database for Auth and Payment services. |

## 🔥 Key Features

### 1. Resilience & Stability
- **Circuit Breaker:** Implemented in API Gateway. If the Payment Service fails 3 times, the circuit opens (fast failure) for 10 seconds.
- **Rate Limiting:** Protects the API from abuse (limit: 5 requests/10s per IP).
- **Exponential Backoff:** Frontend implements retry logic with increasing delays for failed requests.
- **Idempotency:** Payment requests carry unique keys to prevent duplicate charges (cached responses for duplicates).

### 2. Chaos Engineering 💥
Built-in tools to simulate failures and test system resilience:
- **Latency Injection:** Introduce artificial delays (e.g., 2s) in Auth Service.
- **Random Failures:** Simulate 70% failure rate in Payment Service.
- **Crash Mode:** Simulate a complete service outage (503 Service Unavailable).
- **Kill Switch:** Instantly stop the frontend health checks.

### 3. Observability 📊
- **Real-time Dashboard:** Visualizes the health status (UP/DOWN/DEGRADED) of all services.
- **Latency Monitoring:** Tracks response times (ms) for every request.
- **Stress Testing:** Integrated tool to launch concurrent load attacks and verify Rate Limiting/Circuit Breaker.

## 🛠 Installation & Setup

### Prerequisites
- Docker & Docker Compose
- Node.js (optional, for local dev)

### 1. Clone the repository
```bash
git clone https://github.com/MateoDumas/Backplane.git
cd Backplane
```

### 2. Run with Docker (Production Mode)
We use a production-optimized Compose file:
```bash
# Windows (PowerShell)
.\deploy.ps1

# Linux/Mac
docker-compose -f docker-compose.prod.yml up -d --build
```
Access the app at: **http://localhost**

### 3. Local Development
```bash
docker-compose up -d --build
```
Frontend: http://localhost:3003
Gateway: http://localhost:8080

## ☁️ Deployment

### Render (Recommended)
This project includes a `render.yaml` Blueprint for 1-click full-stack deployment.
1. Create a new **Blueprint** in Render.
2. Connect this repository.
3. Render will automatically deploy the Database, Services, and Frontend.

## 🧪 Testing

### Idempotency Test
Send a payment request with a header `Idempotency-Key: <unique-uuid>`.
- **First Request:** Returns `200 OK` (Processed).
- **Second Request:** Returns `200 OK` (Cached result, no new transaction).

### Circuit Breaker Test
1. Enable **Crash Mode** in the Chaos Panel.
2. Send 3+ payment requests.
3. Observe the API Gateway blocking requests immediately (`Circuit Breaker OPEN`).

## 📜 License
This project is licensed under the MIT License.
