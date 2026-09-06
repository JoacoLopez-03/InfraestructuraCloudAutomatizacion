output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint del API server de Kubernetes"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.network.vpc_id
}

output "kubeconfig_command" {
  description = "Comando para configurar kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
