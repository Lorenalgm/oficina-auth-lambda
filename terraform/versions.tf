terraform {
  required_version = ">= 1.5"

  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 5.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.4" }
  }

  backend "s3" {
    key = "auth-lambda/terraform.tfstate"
    # bucket, region e dynamodb_table vêm de -backend-config (ver README).
  }
}

provider "aws" {
  region = var.aws_region
}

# Rede, banco e segredo são criados pelo repositório oficina-infra-db.
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = var.tfstate_bucket
    key    = "infra-db/terraform.tfstate"
    region = var.aws_region
  }
}
