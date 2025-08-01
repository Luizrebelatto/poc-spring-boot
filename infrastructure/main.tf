terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Namespace for the application
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = "poc-spring-boot"
  }
}

# Namespace for monitoring
resource "kubernetes_namespace" "monitoring_namespace" {
  metadata {
    name = "monitoring"
  }
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "poc-spring-boot-config"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    "application.properties" = <<-EOF
      server.port=8080
      management.endpoints.web.exposure.include=health,info,metrics,prometheus
      management.endpoint.health.show-details=always
      management.metrics.export.prometheus.enabled=true
      logging.level.com.example.pocspringboot=INFO
    EOF
  }
}

# ServiceAccount for the application
resource "kubernetes_service_account" "app_service_account" {
  metadata {
    name      = "poc-spring-boot-sa"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }
}

# ClusterRole for monitoring access
resource "kubernetes_cluster_role" "monitoring_role" {
  metadata {
    name = "poc-spring-boot-monitoring"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch"]
  }
}

# ClusterRoleBinding
resource "kubernetes_cluster_role_binding" "monitoring_binding" {
  metadata {
    name = "poc-spring-boot-monitoring"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.monitoring_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.app_service_account.metadata[0].name
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }
}

# PersistentVolumeClaim for application logs
resource "kubernetes_persistent_volume_claim" "app_logs" {
  metadata {
    name      = "poc-spring-boot-logs"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

# Ingress for external access
resource "kubernetes_ingress_v1" "app_ingress" {
  metadata {
    name      = "poc-spring-boot-ingress"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      host = "poc-spring-boot.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "poc-spring-boot-service"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}

# ServiceMonitor for Prometheus
resource "kubernetes_manifest" "service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "poc-spring-boot-monitor"
      namespace = kubernetes_namespace.monitoring_namespace.metadata[0].name
    }
    spec = {
      selector = {
        matchLabels = {
          app = "poc-spring-boot"
        }
      }
      endpoints = [
        {
          port     = "http"
          path     = "/actuator/prometheus"
          interval = "30s"
        }
      ]
    }
  }
}

# PrometheusRule for alerting
resource "kubernetes_manifest" "prometheus_rule" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "poc-spring-boot-rules"
      namespace = kubernetes_namespace.monitoring_namespace.metadata[0].name
    }
    spec = {
      groups = [
        {
          name = "poc-spring-boot.rules"
          rules = [
            {
              alert = "HighCPUUsage"
              expr  = "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 80"
              for  = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "High CPU usage detected"
              }
            },
            {
              alert = "HighMemoryUsage"
              expr  = "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 80"
              for  = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "High memory usage detected"
              }
            }
          ]
        }
      ]
    }
  }
} 