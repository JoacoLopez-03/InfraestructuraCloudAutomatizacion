terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Estado remoto para colaboracion en equipo (DESACTIVADO por defecto).
  # Con el backend comentado, Terraform usa estado LOCAL y el proyecto
  # funciona sin infraestructura previa. Para trabajo en equipo, cree el
  # bucket S3 + tabla DynamoDB y descomente este bloque ajustando el nombre.
  #
  # backend "s3" {
  #   bucket         = "devops-tfstate-<su-bucket>"
  #   key            = "proyecto-final/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "devops-tflock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
