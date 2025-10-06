#!/bin/bash

# Ensure Docker Buildx is available
if ! docker buildx version &> /dev/null; then
    echo "Docker Buildx is not installed or not available. Please install it."
    exit 1
fi

# Create a new builder instance if it doesn't exist
if ! docker buildx inspect multiarch-builder &> /dev/null; then
    docker buildx create --name multiarch-builder --use
else
    docker buildx use multiarch-builder
fi

# Bootstrap the builder
docker buildx inspect multiarch-builder --bootstrap

# Define image name and tag
IMAGE_NAME="ayush183739/krishi-model"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo "Building multi-architecture Docker image: ${FULL_IMAGE_NAME} for platforms linux/amd64,linux/arm64"

# Build and push the multi-architecture image
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag "${FULL_IMAGE_NAME}" \
    --push \
    -f krishi-model/Dockerfile \
    krishi-model/

if [ $? -eq 0 ]; then
    echo "Successfully built and pushed multi-architecture image: ${FULL_IMAGE_NAME}"
else
    echo "Failed to build and push multi-architecture image."
    exit 1
fi