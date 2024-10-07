// Copyright (C) 2021 by Klimenko Maxim Sergievich

terraform {
  backend "s3" {
    bucket = "mks-infra-terraform-state-store"
    key    = "eu-central-1"
    region = "eu-central-1"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.50.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
