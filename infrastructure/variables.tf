variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "poc-spring-boot"
}

variable "app_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "poc-spring-boot"
}

variable "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring"
  type        = string
  default     = "monitoring"
}

variable "replica_count" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

variable "cpu_request" {
  description = "CPU request for the application"
  type        = string
  default     = "250m"
}

variable "cpu_limit" {
  description = "CPU limit for the application"
  type        = string
  default     = "500m"
}

variable "memory_request" {
  description = "Memory request for the application"
  type        = string
  default     = "256Mi"
}

variable "memory_limit" {
  description = "Memory limit for the application"
  type        = string
  default     = "512Mi"
}

variable "storage_size" {
  description = "Storage size for persistent volumes"
  type        = string
  default     = "1Gi"
}

variable "ingress_host" {
  description = "Hostname for ingress"
  type        = string
  default     = "poc-spring-boot.local"
}

variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Enable ingress controller"
  type        = bool
  default     = true
} 