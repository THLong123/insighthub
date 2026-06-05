variable "aws_region" {
  description = "AWS region for managed services."
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Prefix used for AWS and Kubernetes resources."
  type        = string
  default     = "insighthub"
}

variable "vpc_id" {
  description = "Existing VPC ID that hosts the EKS cluster and private services."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS and ElastiCache."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "Provide at least two private subnets, even when single-AZ lab resources are used."
  }
}

variable "eks_node_security_group_ids" {
  description = "Security group IDs attached to EKS worker nodes or pod ENIs."
  type        = list(string)
}

variable "eks_oidc_provider_arn" {
  description = "OIDC provider ARN for the existing EKS cluster, used by IRSA."
  type        = string
}

variable "eks_oidc_issuer_url" {
  description = "OIDC issuer URL for the existing EKS cluster."
  type        = string
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig used by the Kubernetes provider."
  type        = string
  default     = null
}

variable "kubeconfig_context" {
  description = "Optional kubeconfig context for the target EKS cluster."
  type        = string
  default     = null
}

variable "namespace" {
  description = "Kubernetes namespace for InsightHub."
  type        = string
  default     = "insighthub"
}

variable "rds_instance_class" {
  description = "Small lab-friendly RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage_gb" {
  description = "Allocated RDS storage in GiB."
  type        = number
  default     = 20
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection for persistent environments."
  type        = bool
  default     = true
}

variable "redis_node_type" {
  description = "Small lab-friendly ElastiCache node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "allowed_cidr_blocks" {
  description = "Optional extra private CIDR blocks allowed to reach RDS and Redis."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags merged with the common project tags."
  type        = map(string)
  default     = {}
}

