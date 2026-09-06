variable "region" {
  description = "Region de AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto, usado como prefijo en los recursos"
  type        = string
  default     = "devops-final"
}

variable "environment" {
  description = "Entorno (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_version" {
  description = "Version de Kubernetes del cluster EKS"
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  description = "Tipos de instancia para los nodos worker (spot para ahorrar costos)"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Cantidad deseada de nodos"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Cantidad minima de nodos"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Cantidad maxima de nodos (para auto-escalado del cluster)"
  type        = number
  default     = 4
}
