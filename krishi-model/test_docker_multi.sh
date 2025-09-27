#!/bin/bash

# Multi-Model Docker Testing Script for Krishi Sahayak

echo "🚀 Starting Multi-Model Docker Testing"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
print_status "Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi
print_success "Docker is running"

# Stop any existing containers
print_status "Stopping existing containers..."
docker-compose -f docker-compose.multi.yml down > /dev/null 2>&1

# Build the multi-model image
print_status "Building multi-model Docker image..."
if docker build -f Dockerfile.multi -t krishi-ml-multi .; then
    print_success "Docker image built successfully"
else
    print_error "Failed to build Docker image"
    exit 1
fi

# Start the multi-model container
print_status "Starting multi-model container..."
if docker-compose -f docker-compose.multi.yml up -d; then
    print_success "Container started successfully"
else
    print_error "Failed to start container"
    exit 1
fi

# Wait for container to be ready
print_status "Waiting for container to be ready..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        print_success "Container is ready!"
        break
    fi
    
    attempt=$((attempt + 1))
    print_status "Attempt $attempt/$max_attempts - waiting for server..."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    print_error "Container failed to start within 60 seconds"
    print_status "Container logs:"
    docker-compose -f docker-compose.multi.yml logs
    exit 1
fi

# Run tests
print_status "Running multi-model tests..."
if python3 test_multi_model.py; then
    print_success "All tests passed!"
else
    print_error "Some tests failed"
    print_status "Container logs:"
    docker-compose -f docker-compose.multi.yml logs
    exit 1
fi

# Show container status
print_status "Container status:"
docker-compose -f docker-compose.multi.yml ps

# Show resource usage
print_status "Resource usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

print_success "Multi-model Docker testing completed successfully!"
print_status "Container is running at http://localhost:5000"
print_status "To stop the container, run: docker-compose -f docker-compose.multi.yml down"
print_status "To view logs, run: docker-compose -f docker-compose.multi.yml logs -f"
