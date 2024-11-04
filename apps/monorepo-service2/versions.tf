terraform {
  required_version = "~>1.5.7"
  backend "http" {
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0,  < 6.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.0, < 6.0.0"
    }
    opsgenie = {
      source  = "opsgenie/opsgenie"
      version = ">= 0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "2.1.2"
    }
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
}
provider "google-beta" {
  project               = var.project_id
  region                = var.region
  user_project_override = true
}
provider "opsgenie" {
  api_key = data.onepassword_item.opsgenie_api_key.password
  api_url = "api.eu.opsgenie.com" #default is api.opsgenie.com
}
provider "onepassword" {
  op_cli_path = var.onepassword_cli_path
}
