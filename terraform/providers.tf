terraform {

  required_version = ">=1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket       = "kamaldeepsingh-terraform-state-2026"
    key          = "ai-interview-coach/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true

  }
}
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project     = "ai-interview-coach"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}


