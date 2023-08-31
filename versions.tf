terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      version = ">= 4.50.0"
      source  = "hashicorp/aws"
    }
  }
}
