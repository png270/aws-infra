terraform {
  required_version = ">= 1.15.0, < 2.0.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

}

# this code prevents someone from running the project with an incompatible version of terraform

# it also declares the official hashicorp AWS provider

