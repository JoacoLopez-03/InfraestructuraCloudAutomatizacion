# Composicion de modulos: red + cluster EKS

module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  region       = var.region
}

module "eks" {
  source              = "./modules/eks"
  project_name        = var.project_name
  environment         = var.environment
  cluster_version     = var.cluster_version
  subnet_ids          = module.network.private_subnet_ids
  vpc_id              = module.network.vpc_id
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
}
