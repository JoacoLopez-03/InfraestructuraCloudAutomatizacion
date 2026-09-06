terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Estado remoto para colaboracion en equipo.
  # El bucket y la tabla se crean una vez, manualmente o en un stack de bootstrap.
  backend "s3" {
    bucket         = "devops-tfstate-CHANGE-ME"
    key            = "proyecto-final/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-tflock"
    encrypt        = true
  }
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
