# Day 3 production backend template.
# Create the S3 bucket and DynamoDB table once, then replace the placeholders
# before running terraform init without -backend=false.
terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_INSIGHTHUB_TFSTATE_BUCKET"
    key            = "insighthub/day3/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "REPLACE_WITH_INSIGHTHUB_TFLOCK_TABLE"
    encrypt        = true
  }
}

