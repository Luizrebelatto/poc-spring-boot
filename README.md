# Spring Boot POC with Complete CI/CD Flow

This project demonstrates a complete CI/CD pipeline using Jenkins, Helm, OpenTofu, Kubernetes (Minikube), Prometheus, and Grafana.

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Jenkins   │───▶│    Docker   │───▶│   Helm      │───▶│ Kubernetes  │
│   Pipeline  │    │   Registry  │    │   Charts    │    │  (Minikube) │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                              │
                                                              ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  OpenTofu   │◀───│  Prometheus │◀───│   Grafana   │◀───│  Monitoring │
│Infrastructure│    │   Metrics   │    │  Dashboard  │    │    Stack    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

## 🚀 Quick Start

### Prerequisites

- macOS or Linux
- Docker Desktop (for macOS) or Docker Engine (for Linux)
- At least 4GB RAM available for Minikube

### Automated Setup

Run the setup script to install all dependencies and deploy the complete stack:

```bash
./setup.sh
```

This script will:
1. Install all required tools (kubectl, Helm, Minikube, OpenTofu, etc.)
2. Start a Minikube cluster
3. Deploy Prometheus and Grafana monitoring stack
4. Build and deploy the Spring Boot application
5. Apply OpenTofu infrastructure configuration

### Manual Setup

If you prefer to set up manually, follow these steps:

#### 1. Install Tools

**macOS:**
```bash
brew install kubernetes-cli helm minikube docker openjdk@17 gradle opentofu
```

**Linux (Ubuntu/Debian):**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update && sudo apt-get install -y helm

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install OpenTofu
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y tofu
```

#### 2. Start Minikube

```bash
minikube start --profile=poc-cluster --driver=docker --cpus=2 --memory=4096
minikube addons enable ingress --profile=poc-cluster
minikube addons enable metrics-server --profile=poc-cluster
```

#### 3. Deploy Monitoring Stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --set grafana.enabled=true \
    --set grafana.adminPassword=admin \
    --set grafana.service.type=NodePort \
    --set grafana.service.nodePort=30000
```

#### 4. Build and Deploy Application

```bash
# Build application
./gradlew clean build

# Build Docker image
docker build -t poc-spring-boot:latest .

# Deploy with Helm
helm upgrade --install poc-spring-boot helm/poc-spring-boot \
    --namespace default \
    --set image.tag=latest \
    --set service.type=NodePort \
    --set service.nodePort=30001
```

#### 5. Apply OpenTofu Infrastructure

```bash
cd infrastructure
tofu init
tofu plan -out=tfplan
tofu apply tfplan
cd ..
```

## 📊 Monitoring

### Access URLs

After deployment, you can access:

- **Spring Boot Application**: `http://<minikube-ip>:30001`
- **Grafana Dashboard**: `http://<minikube-ip>:30000` (admin/admin)
- **Kubernetes Dashboard**: `minikube dashboard --profile=poc-cluster`

### Get Minikube IP

```bash
minikube ip --profile=poc-cluster
```

## 🔧 Components

### 1. Jenkins Pipeline (`Jenkinsfile`)

The Jenkins pipeline includes:
- **Build**: Compile and test the application
- **SonarQube Analysis**: Code quality checks
- **Docker Build**: Create container image
- **Kubernetes Setup**: Configure Minikube cluster
- **Monitoring Deployment**: Deploy Prometheus and Grafana
- **Application Deployment**: Deploy with Helm
- **Infrastructure as Code**: Apply OpenTofu configuration
- **Health Checks**: Verify deployment
- **Performance Testing**: Basic load testing

### 2. Helm Charts (`helm/poc-spring-boot/`)

- **Deployment**: Application deployment with monitoring annotations
- **Service**: NodePort service for external access
- **Ingress**: External access configuration
- **ServiceMonitor**: Prometheus monitoring configuration
- **PrometheusRule**: Alerting rules
- **ConfigMap**: Application configuration
- **PersistentVolumeClaim**: Log storage
- **ServiceAccount**: RBAC configuration

### 3. OpenTofu Infrastructure (`infrastructure/`)

- **Namespaces**: Application and monitoring namespaces
- **RBAC**: Service accounts and cluster roles
- **ConfigMaps**: Application configuration
- **Ingress**: External access configuration
- **ServiceMonitor**: Prometheus monitoring
- **PrometheusRule**: Alerting rules

### 4. Monitoring Stack

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **AlertManager**: Alerting and notifications
- **ServiceMonitor**: Automatic service discovery

## 🛠️ Development

### Local Development

```bash
# Run locally
./gradlew bootRun

# Run tests
./gradlew test

# Build
./gradlew build
```

### Docker Development

```bash
# Build image
docker build -t poc-spring-boot:latest .

# Run container
docker run -p 8080:8080 poc-spring-boot:latest
```

### Kubernetes Development

```bash
# Deploy to Kubernetes
helm upgrade --install poc-spring-boot helm/poc-spring-boot

# View logs
kubectl logs -f deployment/poc-spring-boot

# Port forward
kubectl port-forward svc/poc-spring-boot 8080:8080
```

## 📈 Monitoring and Observability

### Metrics Endpoints

- **Health Check**: `/actuator/health`
- **Metrics**: `/actuator/metrics`
- **Prometheus**: `/actuator/prometheus`
- **Info**: `/actuator/info`

### Grafana Dashboards

The monitoring stack includes pre-configured dashboards for:
- Application metrics
- Kubernetes cluster metrics
- Prometheus metrics
- Custom application dashboards

### Alerts

Configured alerts for:
- High CPU usage (>80%)
- High memory usage (>80%)
- Application health issues
- Kubernetes resource issues

## 🔍 Troubleshooting

### Common Issues

1. **Minikube not starting**:
   ```bash
   minikube delete --profile=poc-cluster
   minikube start --profile=poc-cluster --driver=docker
   ```

2. **Docker not running**:
   ```bash
   # macOS
   open -a Docker
   
   # Linux
   sudo systemctl start docker
   ```

3. **Port conflicts**:
   ```bash
   # Check what's using the port
   lsof -i :30001
   ```

4. **Helm chart issues**:
   ```bash
   helm uninstall poc-spring-boot
   helm install poc-spring-boot helm/poc-spring-boot
   ```

### Useful Commands

```bash
# View all resources
kubectl get all

# View pods
kubectl get pods

# View services
kubectl get svc

# View logs
kubectl logs -f deployment/poc-spring-boot

# Access Minikube
minikube ssh --profile=poc-cluster

# Open dashboard
minikube dashboard --profile=poc-cluster

# Port forward Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```

## 🧹 Cleanup

```bash
# Remove Helm releases
helm uninstall poc-spring-boot
helm uninstall prometheus -n monitoring

# Remove OpenTofu resources
cd infrastructure
tofu destroy
cd ..

# Stop Minikube
minikube stop --profile=poc-cluster

# Delete Minikube cluster
minikube delete --profile=poc-cluster
```

## 📚 Additional Resources

- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Helm Documentation](https://helm.sh/docs/)
- [OpenTofu Documentation](https://opentofu.org/docs)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.





