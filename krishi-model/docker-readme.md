# Krishi-Model Docker Image Private Deployment Guide

This guide provides instructions for building and deploying the `krishi-model` Docker image privately.

## 1. Build the Docker Image

Navigate to the `krishi-model/` directory and build the Docker image. This will create a local image tagged `krishi-model:latest`.

```bash
cd krishi-model/
docker build -t krishi-model:latest .
```

## 2. Private Deployment Options

### Option A: Deploying to a Local Kubernetes Cluster (e.g., Minikube, Docker Desktop Kubernetes)

If you are deploying to a local Kubernetes cluster that shares the Docker daemon with your build environment, the `krishi-model:latest` image will be directly accessible to your Kubernetes pods.

1.  **Ensure Kubernetes can access local images:**
    *   For Minikube: `minikube docker-env` and then `eval $(minikube docker-env)` in your shell.
    *   For Docker Desktop Kubernetes: This is usually automatic.

2.  **Update Kubernetes Deployment:**
    Ensure your `k8s/deployment-model.yaml` file specifies `image: krishi-model:latest`.

3.  **Apply the Deployment:**
    ```bash
    kubectl apply -f k8s/deployment-model.yaml
    ```

### Option B: Deploying to a Private Docker Registry (e.g., Google Container Registry, AWS ECR, Docker Hub Private Repo)

For production environments or remote Kubernetes clusters, you will need to push the image to a private Docker registry.

1.  **Authenticate to your private registry:**
    Follow your registry's documentation for authentication. For example, for Google Container Registry (GCR):
    ```bash
    gcloud auth configure-docker
    ```
    For Docker Hub:
    ```bash
    docker login
    ```

2.  **Tag the image for your registry:**
    Replace `<your-registry-url>` with your registry's URL (e.g., `gcr.io/your-project-id`, `your-username/`) and `<image-name>` with `krishi-model`.

    ```bash
    docker tag krishi-model:latest <your-registry-url>/krishi-model:latest
    ```
    Example for GCR:
    ```bash
    docker tag krishi-model:latest gcr.io/my-gcp-project/krishi-model:latest
    ```

3.  **Push the image to the private registry:**
    ```bash
    docker push <your-registry-url>/krishi-model:latest
    ```

4.  **Update Kubernetes Deployment:**
    Modify `k8s/deployment-model.yaml` to use the full registry path for the image.
    ```yaml
    # k8s/deployment-model.yaml
    ...
          containers:
            - name: krishi-model
              image: <your-registry-url>/krishi-model:latest # e.g., gcr.io/my-gcp-project/krishi-model:latest
    ...
    ```

5.  **Configure Kubernetes Image Pull Secret (if necessary):**
    If your private registry requires authentication and your Kubernetes cluster is not already configured to pull from it, you will need to create an image pull secret.

    ```bash
    kubectl create secret docker-registry regcred \
      --docker-server=<your-registry-server> \
      --docker-username=<your-username> \
      --docker-password=<your-password> \
      --docker-email=<your-email>
    ```
    Then, add the `imagePullSecrets` to your deployment:
    ```yaml
    # k8s/deployment-model.yaml
    ...
    spec:
      containers:
        - name: krishi-model
          image: <your-registry-url>/krishi-model:latest
      imagePullSecrets:
        - name: regcred
    ...
    ```

6.  **Apply the Deployment:**
    ```bash
    kubectl apply -f k8s/deployment-model.yaml
    ```

## 3. Environment Variables

The `krishi-model/.env` file contains environment variables like `GEMINI_API_KEY`. These are copied into the Docker image during the build process. For Kubernetes deployments, it is recommended to manage sensitive environment variables using Kubernetes Secrets rather than embedding them directly in the image or deployment YAML.

**Example of using Kubernetes Secrets:**

1.  **Create a Secret:**
    ```bash
    kubectl create secret generic krishi-model-env \
      --from-literal=GEMINI_API_KEY="your_gemini_api_key_here"
    ```

2.  **Reference the Secret in your Deployment:**
    ```yaml
    # k8s/deployment-model.yaml
    ...
          containers:
            - name: krishi-model
              image: krishi-model:latest
              env:
                - name: GEMINI_API_KEY
                  valueFrom:
                    secretKeyRef:
                      name: krishi-model-env
                      key: GEMINI_API_KEY
    ...