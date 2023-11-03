
provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">=1"

  # backup "local" {
  #   path = "iac/terraform.tfstate"
  # }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">=4"
    }
     
  }
}