# 🚀 Backplane - Resilient Microservices Architecture

![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)
![Node.js](https://img.shields.io/badge/Node.js-v18-green.svg?style=flat-square&logo=node.js)
![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg?style=flat-square&logo=docker)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791.svg?style=flat-square&logo=postgresql)
![Nginx](https://img.shields.io/badge/Nginx-Proxy-009639.svg?style=flat-square&logo=nginx)
![Status](https://img.shields.io/badge/Status-Production%20Ready-success.svg?style=flat-square)

> **A production-grade microservices demonstration featuring advanced resilience patterns, chaos engineering capabilities, and full observability.**

---

## 🌟 Why This Project?

This repository demonstrates how to build **robust, fault-tolerant distributed systems**. Unlike simple CRUD apps, **Backplane** implements critical architectural patterns required in high-scale enterprise environments:

*   🛡️ **Circuit Breaker**: Prevents cascading failures when a downstream service is down.
*   🚦 **Rate Limiting**: Protects APIs from DDoS and abuse.
*   🔁 **Idempotency**: Ensures financial transactions are processed exactly once, even during network retries.
*   🐵 **Chaos Engineering**: Built-in tools to simulate latency, crashes, and random failures to prove system stability.
*   ☁️ **Cloud Native**: Fully containerized with Docker and deployed via Render Blueprints (Infrastructure as Code).

---

## 🏗 Architecture Overview

The system is composed of decoupled microservices communicating via REST APIs, orchestrated by a central Gateway.

```mermaid
graph TD
    Client[🖥️ Frontend UI (Nginx)] -->|HTTPS| Gateway[🚪 API Gateway]
    
    subgraph "Internal Network (Docker/Render)"
        Gateway -->|Route /auth| Auth[🔐 Auth Service]
        Gateway -->|Route /payments| Payment[💰 Payment Service]
        Gateway -->|Route /notifications| Notif[📨 Notification Service]
        
        Auth -->|Read/Write| DB[(🗄️ PostgreSQL)]
        Payment -->|Read/Write| DB
    end
    
    classDef service fill:#f9f,stroke:#333,stroke-width:2px;
    classDef db fill:#ff9,stroke:#333,stroke-width:2px;
    class Auth,Payment,Notif,Gateway service;
    class DB db;
```

### 🧩 Services Breakdown

| Service | Stack | Responsibilities |
|---------|-------|------------------|
| **Frontend** | Nginx, HTML5, Bootstrap | Responsive Dashboard, Health Monitoring, Chaos Control Panel. |
| **API Gateway** | Node.js, Express, `http-proxy` | Request Routing, **Circuit Breaker**, **Rate Limiting**, SSL Termination. |
| **Auth Service** | Node.js, JWT, `pg` | User Management, Secure Login, Token Generation (JWT). |
| **Payment Service** | Node.js, PostgreSQL | Transaction Processing, **Idempotency Checks**, Chaos Simulation Hooks. |
| **Notification** | Node.js | Async event handling (simulated email/SMS). |
| **Database** | PostgreSQL 15 | Relational persistence for users and financial transactions. |

---

## 🔥 Key Engineering Features

### 1. Resilience Patterns
*   **Circuit Breaker (Opossum/Custom)**: If the Payment Service fails 3 consecutive times, the Gateway "opens the circuit" for 10 seconds, failing fast (503) without overloading the struggling service.
*   **Exponential Backoff**: The frontend client intelligently retries failed requests with increasing delays (1s, 2s, 4s...) to handle transient network blips.
*   **Rate Limiting**: Limits clients to 5 requests per 10 seconds to prevent resource exhaustion.

### 2. Idempotency Implementation
Critical for fintech apps. Every payment request carries a unique `Idempotency-Key` header.
*   **Scenario**: Client sends payment -> Server processes it -> Network fails before response reaches client -> Client retries.
*   **Result**: Server detects the repeated Key, returns the *cached* original success response instead of charging the user twice.

### 3. Chaos Engineering Suite 💥
A dedicated "Chaos Monkey" panel in the frontend allows you to break the system on purpose to verify resilience:
*   **Latency Injection**: Adds 2000ms delay to Auth Service requests.
*   **Random Failures**: Makes Payment Service fail 70% of the time.
*   **Crash Mode**: Simulates a hard crash (Service Unavailable) to trigger the Circuit Breaker.

---

## 🚀 Getting Started

### Prerequisites
*   [Docker Desktop](https://www.docker.com/products/docker-desktop)
*   Git

### Local Installation (Docker Compose)
The easiest way to run the full stack locally:

```bash
# 1. Clone the repository
git clone https://github.com/MateoDumas/Backplane.git
cd Backplane

# 2. Start all services
docker-compose up -d --build
```

**Access the application:**
*   💻 **Dashboard**: [http://localhost:3003](http://localhost:3003)
*   🔌 **API Gateway**: [http://localhost:8080](http://localhost:8080)

---

## ☁️ Deployment

This project is configured for **Zero-Downtime Deployment** on [Render](https://render.com).

### Render Blueprint (Infrastructure as Code)
The `render.yaml` file defines the entire infrastructure:
1.  **PostgreSQL Database** (Managed)
2.  **Web Services** (Auth, Payment, Notification, Gateway)
3.  **Static Site** (Frontend via Nginx container)

All services are connected via a private internal network with DNS discovery.

---

## 🧪 Testing & Verification

### 1. Circuit Breaker Demo
1.  Open the **Chaos Monkey** panel in the Dashboard.
2.  Toggle **"💀 MATAR Payment Service"**.
3.  Try to process a payment.
4.  **Result**: After 3 failures, you will see `CIRCUIT OPEN` badge. The Gateway stops forwarding requests immediately.

### 2. Idempotency Demo
1.  Open Browser DevTools (Network Tab).
2.  Click "Process Payment".
3.  Copy the request as cURL and run it twice in your terminal with the same `Idempotency-Key`.
4.  **Result**: Both return `200 OK`, but only one database entry is created.

---

## 👨‍💻 Author

**Mateo Dumas**  
*Full Stack Software Engineer & Distributed Systems Enthusiast*

*   💼 [LinkedIn](#)
*   🐙 [GitHub](https://github.com/MateoDumas)
*   📧 [Email](#)

---

*Made with ❤️ and Node.js*
