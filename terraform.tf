terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.75"
    }
  }

  cloud {
    organization = "CMI-Product"

    workspaces {
      project = "Cisco SD-WAN Alert API"
      tags    = ["Cisco-Alert-state"]
    }
  }
}

// configure the provider
provider "aws" {
  region = "ap-southeast-1"
}