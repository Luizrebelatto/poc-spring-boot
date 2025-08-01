output "app_namespace" {
  description = "Application namespace name"
  value       = kubernetes_namespace.app_namespace.metadata[0].name
}

output "monitoring_namespace" {
  description = "Monitoring namespace name"
  value       = kubernetes_namespace.monitoring_namespace.metadata[0].name
}

output "service_account_name" {
  description = "Service account name for the application"
  value       = kubernetes_service_account.app_service_account.metadata[0].name
}

output "config_map_name" {
  description = "ConfigMap name for application configuration"
  value       = kubernetes_config_map.app_config.metadata[0].name
}

output "ingress_host" {
  description = "Ingress hostname"
  value       = var.ingress_host
}

output "cluster_role_name" {
  description = "Cluster role name for monitoring"
  value       = kubernetes_cluster_role.monitoring_role.metadata[0].name
}

output "persistent_volume_claim_name" {
  description = "Persistent volume claim name for logs"
  value       = kubernetes_persistent_volume_claim.app_logs.metadata[0].name
}

output "service_monitor_name" {
  description = "ServiceMonitor name for Prometheus"
  value       = "poc-spring-boot-monitor"
}

output "prometheus_rule_name" {
  description = "PrometheusRule name for alerting"
  value       = "poc-spring-boot-rules"
}

output "access_urls" {
  description = "Access URLs for the application and monitoring"
  value = {
    application = "http://${var.ingress_host}"
    grafana     = "http://${var.ingress_host}:30000"
    prometheus  = "http://${var.ingress_host}:30000"
  }
} 