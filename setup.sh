#!/bin/bash

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

# Check if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Detected macOS"
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew is not installed. Please install it first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    # Install required tools
    print_status "Installing required tools..."
    brew install kubernetes-cli helm minikube docker openjdk@17 gradle
    
    # Install OpenTofu
    brew install opentofu
    
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    print_status "Detected Linux"
    
    # Install required tools for Ubuntu/Debian
    if command -v apt-get &> /dev/null; then
        print_status "Installing required tools for Ubuntu/Debian..."
        sudo apt-get update
        sudo apt-get install -y curl wget git
        
        # Install Docker
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        
        # Install kubectl
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        
        # Install Helm
        curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
        sudo apt-get update
        sudo apt-get install -y helm
        
        # Install Minikube
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        
        # Install OpenTofu
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt-get update
        sudo apt-get install -y tofu
        
        # Install Java
        sudo apt-get install -y openjdk-17-jdk
        
        # Install Gradle
        sudo apt-get install -y gradle
    else
        print_error "Unsupported Linux distribution. Please install the tools manually."
        exit 1
    fi
else
    print_error "Unsupported operating system: $OSTYPE"
    exit 1
fi

# Start Docker service
print_status "Starting Docker service..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    open -a Docker
    sleep 10
else
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# Start Minikube
print_status "Starting Minikube cluster..."
minikube start --profile=poc-cluster --driver=docker --cpus=2 --memory=4096

# Enable Minikube addons
print_status "Enabling Minikube addons..."
minikube addons enable ingress --profile=poc-cluster
minikube addons enable metrics-server --profile=poc-cluster
minikube addons enable dashboard --profile=poc-cluster

# Add Helm repositories
print_status "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Deploy monitoring stack
print_status "Deploying monitoring stack..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
    --set grafana.enabled=true \
    --set grafana.adminPassword=admin \
    --set grafana.service.type=NodePort \
    --set grafana.service.nodePort=30000

# Build the application
print_status "Building Spring Boot application..."
./gradlew clean build

# Build Docker image
print_status "Building Docker image..."
docker build -t poc-spring-boot:latest .

# Deploy application with Helm
print_status "Deploying application with Helm..."
helm upgrade --install poc-spring-boot helm/poc-spring-boot \
    --namespace default \
    --set image.tag=latest \
    --set service.type=NodePort \
    --set service.nodePort=30001

# Apply OpenTofu infrastructure
print_status "Applying OpenTofu infrastructure..."
cd infrastructure
tofu init
tofu plan -out=tfplan
tofu apply tfplan
cd ..

# Wait for deployment
print_status "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/poc-spring-boot

# Get Minikube IP
MINIKUBE_IP=$(minikube ip --profile=poc-cluster)

print_success "Setup completed successfully!"
echo ""
echo "=== Access URLs ==="
echo "Spring Boot App: http://$MINIKUBE_IP:30001"
echo "Grafana: http://$MINIKUBE_IP:30000 (admin/admin)"
echo "Kubernetes Dashboard: minikube dashboard --profile=poc-cluster"
echo ""
echo "=== Useful Commands ==="
echo "View logs: kubectl logs -f deployment/poc-spring-boot"
echo "Port forward: kubectl port-forward svc/poc-spring-boot 8080:8080"
echo "Access Minikube: minikube ssh --profile=poc-cluster"
echo "Stop cluster: minikube stop --profile=poc-cluster"
echo "Delete cluster: minikube delete --profile=poc-cluster" 