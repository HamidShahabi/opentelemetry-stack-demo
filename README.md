# Spring Boot Observability Stack with OpenTelemetry

This project demonstrates a complete Observability stack for a Spring Boot application using **OpenTelemetry (OTel)**. It captures **Traces**, **Metrics**, and **Logs** and sends them to a backend stack consisting of **Jaeger**, **Prometheus**, and **Loki**, visualized via **Grafana**.

The project supports two deployment modes:
1.  **Local Dev:** Docker Compose + Maven (running the app locally).
2.  **Kubernetes:** Fully containerized deployment on a local Kubernetes cluster.

---

## 🏗 Architecture

**Data Flow:**
`Spring Boot App (OTel Agent)` → `OpenTelemetry Collector` → `Backends`

* **Traces** → Jaeger
* **Metrics** → Prometheus
* **Logs** → Loki
* **Visualization** → Grafana (Dashboards for Metrics & Logs)

---

## 🚀 Prerequisites

* **Java 17+** (JDK 21 recommended)
* **Maven 3.6+**
* **Docker Desktop** (with Kubernetes enabled)
* **kubectl** CLI

---

## 📦 Project Setup

### 1. Spring Boot Application
The application uses the **OpenTelemetry Java Agent** to auto-instrument the code. No manual spans are required, but `JdbcTemplate` is used to demonstrate database tracing.

**Key Dependencies:**
* `spring-boot-starter-jdbc`
* `postgresql` (Driver)
* `spring-boot-starter-web`

**Maven Configuration (`pom.xml`):**
The `pom.xml` is configured to:
1.  Automatically download the `opentelemetry-javaagent.jar` during build.
2.  Attach it to the application start command via `spring-boot-maven-plugin`.

### 2. Database Schema
The app automatically initializes the schema on startup using `src/main/resources/schema.sql`:
```sql
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255)
);
```


---

## 🛠 Mode 1: Local Development (Docker Compose)

Use this mode for rapid development and debugging.

### 1. Start Infrastructure

Run the observability stack (Collector, Jaeger, Loki, Prometheus, Postgres, Grafana).

```bash
docker-compose up -d

```

### 2. Run the Application

Start the Spring Boot app. Maven will handle the OTel agent attachment.

```bash
mvn spring-boot:run

```

### 3. Generate Traffic

Trigger the test endpoint to generate traces and logs.

```bash
curl http://localhost:8080/test-trace

```

---

## ☸️ Mode 2: Kubernetes Deployment

Use this mode to simulate a production-like orchestration environment.

### 1. Build Docker Image

Build the application image locally. Docker Desktop's K8s will see this image without pushing to a registry.

```bash
mvn clean package -DskipTests
docker build -t my-spring-app:latest .

```

### 2. Apply Configurations

Create the ConfigMaps for the OTel Collector and Prometheus.

```bash
kubectl apply -f k8s-configs.yaml

```

### 3. Deploy Infrastructure

Deploy the backend services (Postgres, Jaeger, Loki, Prometheus, OTel Collector, Grafana).

```bash
kubectl apply -f k8s-infra.yaml

```

### 4. Deploy Application

Deploy the Spring Boot app.

```bash
kubectl apply -f k8s-app.yaml

```

### 5. Access Services (Port Forwarding)

Since services run inside the cluster, use port-forwarding to access them.

```bash
# App
kubectl port-forward svc/my-spring-app 8080:8080 &

# Jaeger UI
kubectl port-forward svc/jaeger 16686:16686 &

# Grafana UI
kubectl port-forward svc/grafana 3000:3000 &

```

---

## 📊 Observability & Testing

### 1. Jaeger (Traces)

* **URL:** [http://localhost:16686](https://www.google.com/search?q=http://localhost:16686)
* **Usage:** Select `my-spring-app` -> **Find Traces**.
* **What to look for:**
* Trace showing: `GET /test-trace` → `SELECT users` (Database Span).
* Click span tags to see the executed SQL query.



### 2. Grafana (Logs & Metrics)

* **URL:** [http://localhost:3000](https://www.google.com/search?q=http://localhost:3000)
* **Login:** `admin` / `admin`
* **Setup:**
* Go to **Connections > Data Sources**.
* Add **Loki** (`http://loki:3100`).
* Add **Prometheus** (`http://prometheus:9090`).



#### Viewing Logs (Loki)

1. Go to **Explore** -> Select **Loki**.
2. Query: `{exporter="OTLP"}`.
3. **Feature:** Look for the **TraceID** in the logs. Click it to jump to Jaeger.

#### Viewing Metrics (Prometheus)

1. Go to **Explore** -> Select **Prometheus**.
2. Query: `http_server_request_duration_seconds_count`.

---

## 🐛 Troubleshooting

| Issue | Solution |
| --- | --- |
| **Connection Refused (4318)** | Ensure `otel-collector` container is running. Check `docker ps`. |
| **404 Not Found (Logs)** | Ensure OTel Collector config uses `otlphttp/loki` exporter, not `loki` (deprecated). |
| **No Traces in Jaeger** | Verify `OTEL_EXPORTER_OTLP_ENDPOINT` is correct (`http://localhost:4318` for local, `http://otel-collector:4318` for K8s). |
| **App fails in K8s** | Check if the image `my-spring-app:latest` exists locally. Ensure `imagePullPolicy: Never` is set in deployment. |

```

```