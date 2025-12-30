#!/bin/bash

echo "=== OpenTelemetry Metrics Troubleshooting Script ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: Docker services
echo "1. Checking Docker Services..."
echo "================================"
if docker ps | grep -q "prometheus"; then
    echo -e "${GREEN}✓ Prometheus is running${NC}"
else
    echo -e "${RED}✗ Prometheus is NOT running${NC}"
    echo "  Fix: docker-compose up -d prometheus"
fi

if docker ps | grep -q "otel-collector"; then
    echo -e "${GREEN}✓ OTEL Collector is running${NC}"
else
    echo -e "${RED}✗ OTEL Collector is NOT running${NC}"
    echo "  Fix: docker-compose up -d otel-collector"
fi

if docker ps | grep -q "postgres"; then
    echo -e "${GREEN}✓ PostgreSQL is running${NC}"
else
    echo -e "${RED}✗ PostgreSQL is NOT running${NC}"
    echo "  Fix: docker-compose up -d postgres"
fi

echo ""

# Check 2: Spring Boot App
echo "2. Checking Spring Boot Application..."
echo "========================================"
if curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Spring Boot app is running${NC}"

    # Check if actuator/prometheus endpoint exists
    if curl -s http://localhost:8080/actuator/prometheus | grep -q "http_server_requests"; then
        echo -e "${GREEN}✓ Spring Boot metrics endpoint is working${NC}"
        METRIC_COUNT=$(curl -s http://localhost:8080/actuator/prometheus | grep -c "^[a-z]")
        echo "  Found ${METRIC_COUNT} metrics"
    else
        echo -e "${RED}✗ Spring Boot metrics endpoint not working${NC}"
        echo "  Fix: Check if micrometer-registry-prometheus is in pom.xml"
    fi
else
    echo -e "${RED}✗ Spring Boot app is NOT running${NC}"
    echo "  Fix: ./mvnw spring-boot:run"
fi

echo ""

# Check 3: OTEL Collector
echo "3. Checking OTEL Collector Metrics Endpoint..."
echo "================================================"
if curl -s http://localhost:8889/metrics > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OTEL Collector metrics endpoint is accessible${NC}"
    OTEL_METRIC_COUNT=$(curl -s http://localhost:8889/metrics | grep -c "^[a-z]")
    echo "  Found ${OTEL_METRIC_COUNT} metrics exposed by OTEL Collector"

    if [ "$OTEL_METRIC_COUNT" -gt 10 ]; then
        echo -e "${GREEN}✓ OTEL Collector is receiving and exposing metrics${NC}"
    else
        echo -e "${YELLOW}⚠ OTEL Collector has very few metrics - may not be receiving data from app${NC}"
    fi
else
    echo -e "${RED}✗ OTEL Collector metrics endpoint not accessible${NC}"
    echo "  Fix: Check OTEL Collector logs: docker-compose logs otel-collector"
fi

echo ""

# Check 4: Prometheus Targets
echo "4. Checking Prometheus Configuration..."
echo "=========================================="
if curl -s http://localhost:9090/api/v1/targets > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Prometheus API is accessible${NC}"

    # Check if otel-collector target is UP
    TARGETS_JSON=$(curl -s http://localhost:9090/api/v1/targets)
    if echo "$TARGETS_JSON" | grep -q '"job":"otel-collector"'; then
        echo -e "${GREEN}✓ OTEL Collector target is configured in Prometheus${NC}"

        if echo "$TARGETS_JSON" | grep -A 5 '"job":"otel-collector"' | grep -q '"health":"up"'; then
            echo -e "${GREEN}✓ OTEL Collector target is UP${NC}"
        else
            echo -e "${RED}✗ OTEL Collector target is DOWN${NC}"
            echo "  Fix: Check if otel-collector:8889 is reachable from Prometheus container"
        fi
    else
        echo -e "${RED}✗ OTEL Collector target not found in Prometheus${NC}"
        echo "  Fix: Check prometheus.yml configuration"
    fi
else
    echo -e "${RED}✗ Prometheus API not accessible${NC}"
    echo "  Fix: Check if Prometheus is running: docker-compose up -d prometheus"
fi

echo ""

# Check 5: Sample Metrics Query
echo "5. Checking for HTTP Request Metrics in Prometheus..."
echo "======================================================="
if curl -s http://localhost:9090/api/v1/query?query=http_server_requests_seconds_count > /dev/null 2>&1; then
    QUERY_RESULT=$(curl -s "http://localhost:9090/api/v1/query?query=http_server_requests_seconds_count")
    if echo "$QUERY_RESULT" | grep -q '"resultType":"vector"'; then
        RESULT_COUNT=$(echo "$QUERY_RESULT" | grep -o '"metric"' | wc -l)
        if [ "$RESULT_COUNT" -gt 0 ]; then
            echo -e "${GREEN}✓ Found http_server_requests_seconds_count metric in Prometheus!${NC}"
            echo "  Total time series: ${RESULT_COUNT}"
        else
            echo -e "${YELLOW}⚠ Metric exists but no data yet${NC}"
            echo "  Fix: Generate some traffic: curl http://localhost:8080/test-trace"
        fi
    else
        echo -e "${RED}✗ No http_server_requests_seconds_count metric found${NC}"
        echo "  This means metrics are not flowing from app -> OTEL -> Prometheus"
    fi
fi

echo ""

# Check 6: Docker Network
echo "6. Checking Docker Network..."
echo "==============================="
NETWORK=$(docker inspect opentelemetry-stack-demo_otel-collector_1 2>/dev/null | grep -o '"NetworkMode": "[^"]*"' | cut -d'"' -f4)
if [ -n "$NETWORK" ]; then
    echo -e "${GREEN}✓ Containers are on network: ${NETWORK}${NC}"
else
    echo -e "${YELLOW}⚠ Could not determine network${NC}"
fi

echo ""
echo "=== Summary ==="
echo "==============="
echo ""
echo "Quick Fixes:"
echo "1. Start all services: docker-compose up -d"
echo "2. Rebuild and run app: ./mvnw clean package && ./mvnw spring-boot:run"
echo "3. Generate traffic: curl http://localhost:8080/test-trace"
echo "4. Wait 30 seconds for metrics to appear"
echo "5. Check Prometheus targets: http://localhost:9090/targets"
echo "6. Query metrics in Prometheus: http://localhost:9090"
echo ""
echo "Useful URLs:"
echo "  - Spring Boot Metrics: http://localhost:8080/actuator/prometheus"
echo "  - OTEL Collector Metrics: http://localhost:8889/metrics"
echo "  - Prometheus UI: http://localhost:9090"
echo "  - Prometheus Targets: http://localhost:9090/targets"
echo "  - Grafana: http://localhost:3000"
echo ""

