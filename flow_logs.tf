/*
  Enable VPC Flow Logs
*/

resource "aws_flow_log" "s3_vpc_log" {
  count                = var.build_s3_flow_logs ? 1 : 0
  log_destination      = aws_s3_bucket.vpc_log_bucket[count.index].arn
  log_destination_type = "s3"
  vpc_id               = aws_vpc.vpc.id
  traffic_type         = "ALL"
}

resource "aws_s3_bucket" "vpc_log_bucket" {
  count         = var.build_s3_flow_logs ? 1 : 0
  tags          = merge(local.base_tags, var.custom_tags)
  bucket        = var.logging_bucket_name
  force_destroy = var.logging_bucket_force_destroy
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  count  = var.build_s3_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.vpc_log_bucket[0].id

  rule {
    id = "Expire old versions"
    filter {
      prefix = var.logging_bucket_prefix
    }

    expiration {
      days = var.logging_bucket_retention
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  count  = var.build_s3_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.vpc_log_bucket[0].id
  acl    = var.logging_bucket_access_control
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  count  = var.build_s3_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.vpc_log_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.logging_bucket_encryption_kms_mster_key
      sse_algorithm     = var.logging_bucket_encryption
    }
  }
}

resource "aws_flow_log" "cw_vpc_log" {
  count           = var.build_flow_logs ? 1 : 0
  log_destination = aws_cloudwatch_log_group.flowlog_group[count.index].arn
  iam_role_arn    = aws_iam_role.flowlog_role[count.index].arn
  vpc_id          = aws_vpc.vpc.id
  traffic_type    = "ALL"
}

resource "aws_cloudwatch_log_group" "flowlog_group" {
  count = var.build_flow_logs ? 1 : 0
  name  = "${var.vpc_name}-FlowLogs"
}

resource "aws_iam_role" "flowlog_role" {
  count = var.build_flow_logs ? 1 : 0
  name  = "${var.vpc_name}-FlowLogsRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "flowlog_policy" {
  count = var.build_flow_logs ? 1 : 0
  name  = "${var.vpc_name}-FlowLogsPolicy"
  role  = aws_iam_role.flowlog_role[count.index].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "${aws_cloudwatch_log_group.flowlog_group[count.index].arn}"
    }
  ]
}
EOF
}
