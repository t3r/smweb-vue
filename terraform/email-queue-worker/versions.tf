terraform {
  required_version = ">= 1.5"

  # Provide values at init, e.g.:
  #   terraform init -backend-config="bucket=..." -backend-config="key=email-queue-worker/terraform.tfstate" -backend-config="region=..." -backend-config="encrypt=true"
  # Optional lock table: -backend-config="dynamodb_table=terraform-locks"
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  dynamic "assume_role" {
    for_each = trimspace(var.assume_role_arn) != "" ? [1] : []
    content {
      role_arn     = var.assume_role_arn
      session_name = "terraform-fg-email-queue-worker"
    }
  }
}
