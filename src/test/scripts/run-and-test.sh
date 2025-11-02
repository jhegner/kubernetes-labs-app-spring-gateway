#!/bin/bash

# Script to run Spring Boot app, test with curl, and exit
# Usage: ./scripts/run-and-test.sh

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PORT=8080
MAX_WAIT=60  # Maximum seconds to wait for app startup
CHECK_INTERVAL=2  # Seconds between health checks

echo -e "${YELLOW}Starting Spring Boot application...${NC}"

# Start Spring Boot app in background with dev profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev > app.log 2>&1 &
APP_PID=$!

echo -e "${YELLOW}App started with PID: $APP_PID${NC}"

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Stopping application (PID: $APP_PID)...${NC}"
    kill $APP_PID 2>/dev/null || true
    wait $APP_PID 2>/dev/null || true
    echo -e "${GREEN}Application stopped.${NC}"
}

# Trap EXIT signal to ensure cleanup
trap cleanup EXIT INT TERM

# Wait for application to be ready
echo -e "${YELLOW}Waiting for application to start on port $PORT...${NC}"
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    if curl -s http://localhost:$PORT/actuator/health > /dev/null 2>&1; then
        echo -e "${GREEN}Application is ready!${NC}"
        break
    fi
    sleep $CHECK_INTERVAL
    ELAPSED=$((ELAPSED + CHECK_INTERVAL))
    echo -e "${YELLOW}Still waiting... (${ELAPSED}s)${NC}"
done

# Check if app started successfully
if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo -e "${RED}ERROR: Application failed to start within ${MAX_WAIT} seconds${NC}"
    echo -e "${YELLOW}Last 20 lines of app.log:${NC}"
    tail -n 20 app.log
    exit 1
fi

# Give it one more second to fully stabilize
sleep 1

echo -e "\n${YELLOW}=== Running curl tests ===${NC}\n"

# Run the curl test
echo -e "${YELLOW}Testing GET /api/users...${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:$PORT/api/users)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Success! HTTP $HTTP_CODE${NC}"
    echo -e "${GREEN}Response:${NC}"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    EXIT_CODE=0
else
    echo -e "${RED}✗ Failed! HTTP $HTTP_CODE${NC}"
    echo -e "${RED}Response:${NC}"
    echo "$BODY"
    EXIT_CODE=1
fi

echo -e "\n${YELLOW}=== Test completed ===${NC}\n"

# Exit with appropriate code
exit $EXIT_CODE
