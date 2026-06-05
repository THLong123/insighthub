output "namespace" {
  description = "Kubernetes namespace created for InsightHub."
  value       = kubernetes_namespace_v1.insighthub.metadata[0].name
}

output "database_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = aws_db_instance.postgres.address
}

output "database_secret_arn" {
  description = "Secrets Manager ARN for database credentials."
  value       = aws_secretsmanager_secret.database.arn
}

output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_secret_arn" {
  description = "Secrets Manager ARN for Redis auth token."
  value       = aws_secretsmanager_secret.redis.arn
}

output "pod_service_account" {
  description = "Kubernetes ServiceAccount annotated for IRSA."
  value       = kubernetes_service_account_v1.api.metadata[0].name
}

