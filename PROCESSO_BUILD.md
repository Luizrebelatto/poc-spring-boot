# Complete CI/CD Flow Documentation

This document describes the complete CI/CD pipeline implementation using Jenkins, Helm, OpenTofu, Kubernetes (Minikube), Prometheus, and Grafana.

## 🏗️ Architecture Overview

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

## 🔄 CI/CD Pipeline Flow

### 1. Jenkins Pipeline Stages

#### Stage 1: Checkout
- Clones the source code from Git repository
- Sets up the workspace for the build

#### Stage 2: Build
- Runs `./gradlew clean build`
- Compiles the Spring Boot application
- Runs unit tests
- Generates JAR artifacts

#### Stage 3: Test
- Executes all tests with `./gradlew test`
- Publishes test results to Jenkins
- Generates test reports

#### Stage 4: SonarQube Analysis
- Performs code quality analysis
- Checks for code smells, bugs, and vulnerabilities
- Generates quality reports

#### Stage 5: Build Docker Image
- Builds Docker image with application
- Tags image with build number
- Pushes to Docker registry

#### Stage 6: Setup Kubernetes Cluster
- Starts Minikube cluster if not running
- Enables required addons (ingress, metrics-server)
- Configures kubectl context

#### Stage 7: Deploy Monitoring Stack
- Deploys Prometheus and Grafana using Helm
- Configures ServiceMonitors for application monitoring
- Sets up alerting rules

#### Stage 8: Deploy Application with Helm
- Updates Helm values with new image tag
- Deploys application using Helm charts
- Configures NodePort service for external access

#### Stage 9: Infrastructure as Code with OpenTofu
- Initializes OpenTofu configuration
- Plans infrastructure changes
- Applies infrastructure configuration

#### Stage 10: Health Check
- Waits for deployment to be ready
- Tests application endpoints
- Verifies monitoring endpoints

#### Stage 11: Performance Test
- Runs basic load tests
- Validates application performance

### 2. Helm Deployment Process

#### Pre-deployment
1. **Chart Preparation**
   - Updates `values.yaml` with new image tag
   - Configures monitoring annotations
   - Sets up resource limits and requests

2. **Infrastructure Setup**
   - Creates namespaces (application, monitoring)
   - Sets up RBAC (ServiceAccount, ClusterRole)
   - Configures ConfigMaps and PersistentVolumeClaims

#### Deployment
1. **Application Deployment**
   ```bash
   helm upgrade --install poc-spring-boot helm/poc-spring-boot \
       --namespace default \
       --set image.tag=${DOCKER_TAG} \
       --set service.type=NodePort \
       --set service.nodePort=30001
   ```

2. **Monitoring Configuration**
   - ServiceMonitor for Prometheus scraping
   - PrometheusRule for alerting
   - Ingress for external access

### 3. OpenTofu Infrastructure Management

#### Infrastructure Components
1. **Namespaces**
   - Application namespace (`poc-spring-boot`)
   - Monitoring namespace (`monitoring`)

2. **RBAC Configuration**
   - ServiceAccount for application
   - ClusterRole for monitoring access
   - ClusterRoleBinding for permissions

3. **Application Configuration**
   - ConfigMap with application properties
   - Environment variables for monitoring

4. **Monitoring Setup**
   - ServiceMonitor for Prometheus
   - PrometheusRule for alerting
   - Ingress configuration

#### OpenTofu Commands
```bash
# Initialize
tofu init

# Plan changes
tofu plan -out=tfplan

# Apply changes
tofu apply tfplan

# Destroy resources
tofu destroy
```

### 4. Monitoring Stack

#### Prometheus Configuration
- **Scraping**: Automatically discovers and scrapes application metrics
- **Metrics**: Collects JVM, HTTP, and system metrics
- **Storage**: Time-series database for metrics storage
- **Alerting**: Rules for CPU, memory, and application health

#### Grafana Configuration
- **Dashboards**: Pre-configured dashboards for application metrics
- **Data Sources**: Prometheus as primary data source
- **Alerts**: Visual alerting and notifications
- **Users**: Admin user with default credentials (admin/admin)

#### Application Metrics
- **HTTP Metrics**: Request rate, response time, error rate
- **JVM Metrics**: Memory usage, GC statistics, thread count
- **System Metrics**: CPU usage, memory usage, disk I/O
- **Custom Metrics**: Business-specific metrics

### 5. Kubernetes Cluster (Minikube)

#### Cluster Configuration
- **Profile**: `poc-cluster`
- **Driver**: Docker
- **Resources**: 2 CPUs, 4GB RAM
- **Addons**: Ingress, Metrics Server, Dashboard

#### Service Configuration
- **Type**: NodePort for external access
- **Ports**: 8080 (application), 30001 (external)
- **Annotations**: Prometheus scraping configuration

#### Ingress Configuration
- **Class**: nginx
- **Host**: poc-spring-boot.local
- **Paths**: Root path for application access

## 🛠️ Tools and Technologies

### 1. Jenkins
- **Purpose**: CI/CD pipeline orchestration
- **Features**: Multi-stage pipeline, artifact management, test reporting
- **Plugins**: Docker, Kubernetes, SonarQube, Test Results

### 2. Helm
- **Purpose**: Kubernetes package manager
- **Features**: Chart templating, value management, release management
- **Charts**: Application deployment, monitoring stack

### 3. OpenTofu
- **Purpose**: Infrastructure as Code
- **Features**: Resource management, state management, planning
- **Providers**: Kubernetes, Helm

### 4. Kubernetes (Minikube)
- **Purpose**: Container orchestration
- **Features**: Pod management, service discovery, load balancing
- **Components**: API Server, Scheduler, Controller Manager

### 5. Prometheus
- **Purpose**: Metrics collection and monitoring
- **Features**: Time-series database, alerting, service discovery
- **Metrics**: Application, system, and custom metrics

### 6. Grafana
- **Purpose**: Metrics visualization and alerting
- **Features**: Dashboards, alerting, user management
- **Data Sources**: Prometheus, other time-series databases

## 📊 Monitoring and Observability

### Metrics Collection
1. **Application Metrics**
   - HTTP request rate and response time
   - Error rates and status codes
   - Business-specific metrics

2. **JVM Metrics**
   - Memory usage (heap, non-heap)
   - Garbage collection statistics
   - Thread count and status

3. **System Metrics**
   - CPU usage and load
   - Memory usage and availability
   - Disk I/O and network statistics

### Alerting Rules
1. **High CPU Usage**
   - Threshold: >80% for 5 minutes
   - Severity: Warning
   - Action: Scale up or investigate

2. **High Memory Usage**
   - Threshold: >80% for 5 minutes
   - Severity: Warning
   - Action: Increase memory or optimize

3. **Application Health**
   - Threshold: Health check failure
   - Severity: Critical
   - Action: Restart or rollback

### Dashboards
1. **Application Dashboard**
   - Request rate and response time
   - Error rates and status codes
   - JVM memory and GC statistics

2. **System Dashboard**
   - CPU and memory usage
   - Network and disk I/O
   - Pod and container metrics

3. **Kubernetes Dashboard**
   - Cluster resource usage
   - Pod and service status
   - Node health and capacity

## 🔧 Configuration Files

### 1. Jenkinsfile
- Complete CI/CD pipeline definition
- Multi-stage build process
- Integration with all tools

### 2. Helm Charts
- `values.yaml`: Application configuration
- `deployment.yaml`: Pod and container configuration
- `service.yaml`: Service and networking
- `ingress.yaml`: External access configuration
- `servicemonitor.yaml`: Prometheus monitoring
- `prometheusrule.yaml`: Alerting rules

### 3. OpenTofu Configuration
- `main.tf`: Infrastructure resources
- `variables.tf`: Input variables
- `outputs.tf`: Output values

### 4. Monitoring Configuration
- `prometheus.yml`: Prometheus configuration
- `grafana-dashboard.json`: Dashboard definition

## 🚀 Deployment Process

### Automated Deployment
1. **Run Setup Script**
   ```bash
   ./setup.sh
   ```

2. **Manual Deployment**
   ```bash
   # Start Minikube
   minikube start --profile=poc-cluster
   
   # Deploy monitoring
   helm upgrade --install prometheus prometheus-community/kube-prometheus-stack
   
   # Deploy application
   helm upgrade --install poc-spring-boot helm/poc-spring-boot
   
   # Apply infrastructure
   cd infrastructure && tofu apply
   ```

### Verification Steps
1. **Check Pod Status**
   ```bash
   kubectl get pods
   ```

2. **Test Application**
   ```bash
   curl http://$(minikube ip):30001/hello
   ```

3. **Access Monitoring**
   ```bash
   # Grafana
   open http://$(minikube ip):30000
   
   # Kubernetes Dashboard
   minikube dashboard --profile=poc-cluster
   ```

## 🔍 Troubleshooting

### Common Issues
1. **Minikube Not Starting**
   - Check Docker is running
   - Verify system resources
   - Delete and recreate cluster

2. **Application Not Accessible**
   - Check pod status
   - Verify service configuration
   - Check ingress configuration

3. **Monitoring Not Working**
   - Verify ServiceMonitor configuration
   - Check Prometheus targets
   - Validate metrics endpoints

### Debug Commands
```bash
# Check pod logs
kubectl logs -f deployment/poc-spring-boot

# Check service endpoints
kubectl get endpoints

# Check ingress status
kubectl get ingress

# Check monitoring targets
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
```

## 📈 Performance Optimization

### Resource Management
1. **CPU and Memory Limits**
   - Set appropriate resource requests and limits
   - Monitor resource usage
   - Scale based on demand

2. **Horizontal Pod Autoscaling**
   - Configure HPA for automatic scaling
   - Set CPU and memory thresholds
   - Monitor scaling events

3. **Monitoring Optimization**
   - Configure appropriate scrape intervals
   - Set up metric retention policies
   - Optimize alerting rules

### Best Practices
1. **Security**
   - Use RBAC for access control
   - Implement network policies
   - Secure secrets management

2. **Reliability**
   - Implement health checks
   - Set up proper restart policies
   - Configure resource limits

3. **Observability**
   - Comprehensive logging
   - Structured metrics
   - Effective alerting

## 🧹 Cleanup and Maintenance

### Regular Maintenance
1. **Resource Cleanup**
   ```bash
   # Remove Helm releases
   helm uninstall poc-spring-boot
   helm uninstall prometheus -n monitoring
   
   # Remove OpenTofu resources
   cd infrastructure && tofu destroy
   ```

2. **Cluster Management**
   ```bash
   # Stop cluster
   minikube stop --profile=poc-cluster
   
   # Delete cluster
   minikube delete --profile=poc-cluster
   ```

3. **Docker Cleanup**
   ```bash
   # Remove unused images
   docker system prune -a
   
   # Remove unused volumes
   docker volume prune
   ```

This complete CI/CD flow provides a production-ready setup for Spring Boot applications with comprehensive monitoring, infrastructure as code, and automated deployment processes. 