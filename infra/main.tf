locals {
  name        = "${var.name_prefix}-${var.environment}"
  oidc_issuer = replace(var.eks_oidc_issuer_url, "https://", "")

  common_tags = merge(
    {
      Project     = "InsightHub"
      Environment = var.environment
      ManagedBy   = "Terraform"
      CourseDay   = "Day3"
    },
    var.tags
  )
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

resource "kubernetes_namespace_v1" "insighthub" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/name"       = "insighthub"
      "app.kubernetes.io/managed-by" = "terraform"
      "course.insighthub/day"        = "3"
    }
  }
}

resource "random_password" "postgres" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "redis" {
  length  = 32
  special = false
}

resource "aws_kms_key" "insighthub" {
  description             = "KMS key for InsightHub ${var.environment} managed services"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableAccountAdministration"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "insighthub" {
  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.insighthub.key_id
}

resource "aws_secretsmanager_secret" "database" {
  #checkov:skip=CKV2_AWS_57:Rotation Lambda is added after Day 3 when the runtime deployment is wired to managed RDS.
  name                    = "${local.name}/database"
  description             = "InsightHub PostgreSQL connection settings"
  kms_key_id              = aws_kms_key.insighthub.arn
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    username = "insighthub"
    password = random_password.postgres.result
    database = "insighthub"
    port     = 5432
  })
}

resource "aws_secretsmanager_secret" "redis" {
  #checkov:skip=CKV2_AWS_57:Rotation Lambda is added after Day 3 when the runtime deployment is wired to managed Redis.
  name                    = "${local.name}/redis"
  description             = "InsightHub Redis auth token"
  kms_key_id              = aws_kms_key.insighthub.arn
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({
    auth_token = random_password.redis.result
    port       = 6379
  })
}

resource "aws_security_group" "database" {
  name        = "${local.name}-rds"
  description = "Allow InsightHub pods to reach PostgreSQL"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "database_from_nodes" {
  for_each                     = toset(var.eks_node_security_group_ids)
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = each.value
  description                  = "PostgreSQL from EKS worker or pod security group ${each.value}"
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

resource "aws_vpc_security_group_ingress_rule" "database_from_private_cidrs" {
  for_each          = toset(var.allowed_cidr_blocks)
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = each.value
  description       = "PostgreSQL from approved private CIDR ${each.value}"
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_vpc_security_group_egress_rule" "database_dns_tcp" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "HTTPS egress for AWS control plane integrations"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_security_group" "redis" {
  name        = "${local.name}-redis"
  description = "Allow InsightHub pods to reach Redis"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_nodes" {
  for_each                     = toset(var.eks_node_security_group_ids)
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = each.value
  description                  = "Redis from EKS worker or pod security group ${each.value}"
  from_port                    = 6379
  ip_protocol                  = "tcp"
  to_port                      = 6379
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_private_cidrs" {
  for_each          = toset(var.allowed_cidr_blocks)
  security_group_id = aws_security_group.redis.id
  cidr_ipv4         = each.value
  description       = "Redis from approved private CIDR ${each.value}"
  from_port         = 6379
  ip_protocol       = "tcp"
  to_port           = 6379
}

resource "aws_vpc_security_group_egress_rule" "redis_https" {
  security_group_id = aws_security_group.redis.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "HTTPS egress for AWS control plane integrations"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_db_subnet_group" "postgres" {
  name       = "${local.name}-postgres"
  subnet_ids = var.private_subnet_ids
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${local.name}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_parameter_group" "postgres" {
  name   = "${local.name}-postgres16"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "${local.name}-postgres"

  engine         = "postgres"
  engine_version = "16"
  instance_class = var.rds_instance_class

  allocated_storage     = var.rds_allocated_storage_gb
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.insighthub.arn

  db_name  = "insighthub"
  username = "insighthub"
  password = random_password.postgres.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = var.rds_multi_az

  auto_minor_version_upgrade          = true
  iam_database_authentication_enabled = true

  backup_retention_period = 7
  backup_window           = "17:00-18:00"
  maintenance_window      = "sun:18:30-sun:19:30"
  copy_tags_to_snapshot   = true

  deletion_protection       = var.rds_deletion_protection
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name}-postgres-final"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.insighthub.arn

  parameter_group_name = aws_db_parameter_group.postgres.name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${local.name}-redis"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${local.name}-redis"
  description          = "InsightHub async ingestion queue"

  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  num_cache_clusters   = var.redis_cache_clusters
  port                 = 6379
  parameter_group_name = "default.redis7"

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  kms_key_id                 = aws_kms_key.insighthub.arn
  auth_token                 = random_password.redis.result

  automatic_failover_enabled = true
  multi_az_enabled           = true
  apply_immediately          = true

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }
}

resource "aws_cloudwatch_log_group" "redis_slow" {
  name              = "/aws/elasticache/${local.name}/redis-slow"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.insighthub.arn
}

resource "aws_iam_role" "insighthub_pod" {
  name = "${local.name}-pod-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
            "${local.oidc_issuer}:sub" = "system:serviceaccount:${var.namespace}:insighthub-api"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "insighthub_pod" {
  name        = "${local.name}-pod-policy"
  description = "Least-privilege runtime access for InsightHub pods"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.database.arn,
          aws_secretsmanager_secret.redis.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.insighthub.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "insighthub_pod" {
  role       = aws_iam_role.insighthub_pod.name
  policy_arn = aws_iam_policy.insighthub_pod.arn
}

resource "kubernetes_service_account_v1" "api" {
  metadata {
    name      = "insighthub-api"
    namespace = kubernetes_namespace_v1.insighthub.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.insighthub_pod.arn
    }
  }
}
