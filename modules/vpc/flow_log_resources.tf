locals {
  flow_logs_bucket_name = try(local.config.flow_logs_bucket_name,
                              join("-",[local.config.name, "vpc-flow-logs"])
                          )
}

resource "aws_s3_bucket" "flow_logs_s3" {
  count  = local.config.enable_flow_log ? 1 : 0
  bucket = local.flow_logs_bucket_name

  tags = merge(
    { 
      Name = local.flow_logs_bucket_name 
    },
    try(local.config.tags,{})
  )
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  count  = local.config.enable_flow_log ? 1 : 0
  bucket = aws_s3_bucket.flow_logs_s3[0].id

  rule {
    id = "30-days-infrequent-access-60-days-glacier-150-day-expire"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs_s3" {
  count  = local.config.enable_flow_log ? 1 : 0
  bucket = aws_s3_bucket.flow_logs_s3[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "flow_logs_s3" {
  count  = local.config.enable_flow_log ? 1 : 0
  bucket = aws_s3_bucket.flow_logs_s3[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "flow_logs_s3" {
  count  = local.config.enable_flow_log ? 1 : 0
  depends_on = [
    aws_s3_bucket_ownership_controls.flow_logs_s3,
    aws_s3_bucket_public_access_block.flow_logs_s3,
  ]

  bucket = aws_s3_bucket.flow_logs_s3[0].id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "flow_logs_s3" {
  count  = local.config.enable_flow_log ? 1 : 0
  bucket = aws_s3_bucket.flow_logs_s3[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "flow_logs_s3" {
  count = local.config.enable_flow_log ? 1 : 0

  # Amazon S3 bucket permissions for flow logs
  # https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-s3.html#flow-logs-s3-permissions
  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.flow_logs_bucket_name}/AWSLogs/*"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"] # this is required otherwise the bucket owner (the AWS account) won't own the object
    }
  }

  statement {
    sid       = "AWSLogDeliveryAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${local.flow_logs_bucket_name}"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  # S3 buckets should require requests to use Secure Socket Layer (AWS Security Hub)
  statement {
    sid     = "AllowSSLRequestsOnly"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.flow_logs_bucket_name}",
      "arn:aws:s3:::${local.flow_logs_bucket_name}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "flow_logs_s3" {
  count  = local.config.enable_flow_log ? 1 : 0
  bucket = aws_s3_bucket.flow_logs_s3[0].id
  policy = data.aws_iam_policy_document.flow_logs_s3[0].json

  depends_on = [
    aws_s3_bucket_public_access_block.flow_logs_s3,
  ]
}
