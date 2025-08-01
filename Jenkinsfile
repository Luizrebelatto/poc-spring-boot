pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'poc-spring-boot'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        HELM_CHART_PATH = 'helm/poc-spring-boot'
        KUBECONFIG = '/home/jenkins/.kube/config'
        MINIKUBE_PROFILE = 'poc-cluster'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                sh './gradlew clean build'
            }
        }
        
        stage('Test') {
            steps {
                sh './gradlew test'
            }
            post {
                always {
                    publishTestResults testResultsPattern: '**/test-results/**/*.xml'
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh './gradlew sonarqube'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    docker.withRegistry('', 'docker-hub-credentials') {
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push('latest')
                    }
                }
            }
        }
        
        stage('Setup Kubernetes Cluster') {
            steps {
                script {
                    // Start Minikube if not running
                    sh 'minikube status --profile=${MINIKUBE_PROFILE} || minikube start --profile=${MINIKUBE_PROFILE} --driver=docker --cpus=2 --memory=4096'
                    
                    // Enable addons
                    sh 'minikube addons enable ingress --profile=${MINIKUBE_PROFILE}'
                    sh 'minikube addons enable metrics-server --profile=${MINIKUBE_PROFILE}'
                    
                    // Setup kubectl context
                    sh 'minikube kubectl --profile=${MINIKUBE_PROFILE} -- get nodes'
                }
            }
        }
        
        stage('Deploy Monitoring Stack') {
            steps {
                script {
                    // Deploy Prometheus and Grafana using Helm
                    sh '''
                        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
                        helm repo add grafana https://grafana.github.io/helm-charts
                        helm repo update
                        
                        # Deploy Prometheus
                        helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
                            --namespace monitoring \
                            --create-namespace \
                            --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
                            --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
                            --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false
                        
                        # Deploy Grafana (if not included in kube-prometheus-stack)
                        helm upgrade --install grafana grafana/grafana \
                            --namespace monitoring \
                            --set adminPassword=admin \
                            --set service.type=NodePort \
                            --set service.nodePort=30000
                    '''
                }
            }
        }
        
        stage('Deploy Application with Helm') {
            steps {
                script {
                    // Update values.yaml with new image tag
                    sh "sed -i 's/tag: \".*\"/tag: \"${DOCKER_TAG}\"/' ${HELM_CHART_PATH}/values.yaml"
                    
                    // Deploy using Helm
                    sh '''
                        helm upgrade --install poc-spring-boot ${HELM_CHART_PATH} \
                            --namespace default \
                            --set image.tag=${DOCKER_TAG} \
                            --set service.type=NodePort \
                            --set service.nodePort=30001
                    '''
                }
            }
        }
        
        stage('Infrastructure as Code with OpenTofu') {
            steps {
                script {
                    // Initialize and apply OpenTofu configuration
                    sh '''
                        cd infrastructure
                        tofu init
                        tofu plan -out=tfplan
                        tofu apply tfplan
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    // Wait for deployment to be ready
                    sh 'kubectl wait --for=condition=available --timeout=300s deployment/poc-spring-boot'
                    
                    // Test the application
                    sh '''
                        # Get Minikube IP
                        MINIKUBE_IP=$(minikube ip --profile=${MINIKUBE_PROFILE})
                        
                        # Test the application endpoint
                        curl -f http://${MINIKUBE_IP}:30001/hello || exit 1
                        
                        # Test Prometheus endpoint
                        curl -f http://${MINIKUBE_IP}:30000/api/health || exit 1
                    '''
                }
            }
        }
        
        stage('Performance Test') {
            steps {
                script {
                    sh '''
                        # Simple load test
                        for i in {1..10}; do
                            curl -s http://${MINIKUBE_IP}:30001/hello > /dev/null
                        done
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Cleanup
                sh 'docker system prune -f'
                
                // Archive artifacts
                archiveArtifacts artifacts: 'build/libs/*.jar', fingerprint: true
                
                // Publish test results
                publishTestResults testResultsPattern: '**/test-results/**/*.xml'
            }
        }
        
        success {
            script {
                // Show access URLs
                sh '''
                    echo "=== Application URLs ==="
                    echo "Spring Boot App: http://$(minikube ip --profile=${MINIKUBE_PROFILE}):30001"
                    echo "Grafana: http://$(minikube ip --profile=${MINIKUBE_PROFILE}):30000 (admin/admin)"
                    echo "Prometheus: http://$(minikube ip --profile=${MINIKUBE_PROFILE}):30000"
                    echo "Kubernetes Dashboard: minikube dashboard --profile=${MINIKUBE_PROFILE}"
                '''
            }
        }
        
        failure {
            script {
                // Cleanup on failure
                sh '''
                    helm uninstall poc-spring-boot || true
                    kubectl delete namespace monitoring || true
                '''
            }
        }
    }
} 