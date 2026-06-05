provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

