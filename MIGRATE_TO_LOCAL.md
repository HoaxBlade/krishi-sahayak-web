# Migration Guide: From Kubernetes to Physical Server Deployment

This guide outlines the steps to migrate the Krishi-Sahayak application from a Kubernetes deployment to a physical server using Docker and Docker Compose, focusing on containerization, image management, and scaling considerations.

## 1. Understanding the Current Kubernetes Setup and Target Architecture

The application currently runs on Kubernetes, leveraging container orchestration for deployment, scaling, and service discovery. The core components are:
*   **Web Application:** (e.g., `krishi_web`)
*   **ML Model Service:** (e.g., `krishi-model`)

For a physical server deployment, we will replicate this containerized environment using Docker and Docker Compose, which provides a simpler way to define and run multi-container Docker applications.

## 2. Prerequisites

Before you begin, ensure the following are installed on your physical server:

*   **Operating System:** A Linux distribution (e.g., Ubuntu, CentOS) is recommended for server deployments.
*   **Docker Engine:** Install Docker on your server. Follow the official Docker documentation for your specific OS.
    ```bash
    # Example for Ubuntu
    sudo apt update
    sudo apt install apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER # Add your user to the docker group to run docker without sudo
    newgrp docker # Activate changes for current session
    ```
*   **Docker Compose:** Install Docker Compose.
    ```bash
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose --version
    ```
*   **Git:** To clone the repository.

## 3. Setting up the Deployment Environment

### 3.1 Clone the Repository

If you haven't already, clone the Krishi-Sahayak repository onto your physical server:

```bash
git clone https://github.com/your-repo/Krishi-Sahayak.git
cd Krishi-Sahayak
```

### 3.2 Environment Variables

Identify and set any necessary environment variables that were previously managed by Kubernetes secrets or config maps. These might include:
*   Database connection strings (e.g., for Supabase, if used by `krishi_web/src/lib/supabase.ts`)
*   API keys for external services (e.g., weather API, if used by `krishi_web/src/lib/weatherService.ts`)
*   Any specific configuration for the ML model service (e.g., model paths, if not hardcoded).

As per the `docker-compose.yml`, these are expected in:
*   `./krishi_web/.env.local` for the web application.
*   `./krishi-model/.env` for the ML model service.

Create these files and populate them with the appropriate values.

### 3.3 Building and Pulling Docker Images

You have two main options for getting your Docker images onto the server:

#### Option A: Build Images Locally on the Server

If you have the source code on the server and Dockerfiles are available (as indicated by `docker-compose.yml`), you can build the images directly:

1.  **Navigate to the project root:**
    ```bash
    cd /path/to/Krishi-Sahayak
    ```
2.  **Build the images using Docker Compose:**
    ```bash
    docker-compose build
    ```
    This will build the `web` and `model` services based on their respective Dockerfiles in `krishi_web` and `krishi-model` directories.

#### Option B: Pull Pre-built Images from a Container Registry

This is the recommended approach for production deployments, similar to how Kubernetes pulls images. You will need to push your images to a public or private container registry (e.g., Docker Hub, Google Container Registry, AWS ECR) first.

1.  **Tag your images (if not already tagged for the registry):**
    ```bash
    docker tag krishi_web_image_name your-registry/your-username/krishi_web:latest
    docker tag krishi_model_image_name your-registry/your-username/krishi_model:latest
    ```
    (Replace `krishi_web_image_name` and `krishi_model_image_name` with the actual image names generated during build or from your `Dockerfile`s, and `your-registry/your-username` with your registry path.)

2.  **Push images to the registry:**
    ```bash
    docker push your-registry/your-username/krishi_web:latest
    docker push your-registry/your-username/krishi_model:latest
    ```

3.  **Update `docker-compose.yml` to use pre-built images:**
    Modify your `docker-compose.yml` to specify the `image` instead of `build`.

    ```yaml
    version: "3.8"

    services:
      web:
        image: your-registry/your-username/krishi_web:latest # Use pre-built image
        ports:
          - "3000:3000"
        depends_on:
          - model
        env_file:
          - ./krishi_web/.env.local
        environment:
          NODE_ENV: production

      model:
        image: your-registry/your-username/krishi_model:latest # Use pre-built image
        env_file:
          - ./krishi-model/.env
        ports:
          - "8000:8000"
    ```

4.  **Pull images on the physical server:**
    ```bash
    docker-compose pull
    ```
    This will download the specified images from your container registry.

## 4. Running the Application with Docker Compose

Once the images are built or pulled, you can start the entire application stack:

1.  **Navigate to the project root:**
    ```bash
    cd /path/to/Krishi-Sahayak
    ```
2.  **Start the services in detached mode:**
    ```bash
    docker-compose up -d
    ```
    This will start the `web` and `model` services in the background.

## 5. Verification

After starting both services:

1.  **Check container status:**
    ```bash
    docker-compose ps
    ```
    Ensure both `web` and `model` containers are running.

2.  **Access the web application:**
    Open your web browser and navigate to `http://your_server_ip:3000`.
    If you have a domain configured, ensure DNS points to your server's IP.

3.  **Test functionalities:**
    Test functionalities that interact with the ML model service (e.g., analysis features) to ensure the frontend can communicate with the local ML backend.
    Check container logs for any errors:
    ```bash
    docker-compose logs web
    docker-compose logs model
    ```

## 6. Scaling Considerations

Unlike Kubernetes, Docker Compose itself does not provide advanced auto-scaling capabilities. Scaling on a physical server with Docker Compose is primarily manual or can be achieved with additional tools.

### 6.1 Manual Scaling

You can manually scale services by specifying the `--scale` flag with `docker-compose up`:

```bash
docker-compose up -d --scale web=2 --scale model=2
```
This will start 2 instances of the `web` service and 2 instances of the `model` service. You will need a load balancer (e.g., Nginx, HAProxy) in front of your `web` service to distribute traffic across multiple instances.

### 6.2 Load Balancing

For multiple instances of your `web` service, you'll need a reverse proxy/load balancer.

*   **Nginx/HAProxy:** You can set up Nginx or HAProxy on the same server (or a separate one) to distribute incoming traffic to your `web` containers. This would involve configuring Nginx to proxy requests to `web:3000` (or whatever internal port Docker exposes).

### 6.3 Monitoring and Alerting

To make informed scaling decisions, implement monitoring for your server and application metrics (CPU, memory, request latency, error rates). Tools like Prometheus and Grafana can be used for this.

### 6.4 Advanced Orchestration (Future Consideration)

If manual scaling and basic load balancing become insufficient, consider migrating to a more robust orchestration solution designed for physical servers, such as:
*   **Docker Swarm:** Docker's native clustering solution, simpler than Kubernetes but offers orchestration features.
*   **Nomad:** A flexible workload orchestrator by HashiCorp.
*   **Kubernetes (Self-Managed):** If you require the full power of Kubernetes but on your own infrastructure, you can set up a self-managed Kubernetes cluster.

## 7. Troubleshooting

*   **Port Conflicts:** Ensure no other processes on your server are using ports 3000 or 8000.
*   **Environment Variables:** Verify `.env.local` and `.env` files are correctly populated and accessible by Docker Compose.
*   **Firewall:** Ensure your server's firewall (e.g., `ufw`, `firewalld`) allows incoming traffic on ports 3000 (for web) and any other necessary ports.
*   **Docker Logs:** Use `docker-compose logs [service_name]` to inspect logs for specific services.
*   **Image Pull Issues:** Check your registry credentials if pulling from a private registry. Ensure Docker is logged in (`docker login`).

This guide provides a comprehensive approach to deploying Krishi-Sahayak on a physical server using Docker and Docker Compose.