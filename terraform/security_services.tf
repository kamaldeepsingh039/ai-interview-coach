data "aws_caller_identity" "current" {}



resource "aws_s3_bucket_policy" "cloudtrail_logs_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },

      {
        Sid       = "AWSConfigBucketPermissionsCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid       = "AWSConfigBucketDelivery"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }


    ]
  })
}


resource "aws_cloudtrail" "icoach_trail" {
  name           = "icoach-cloud-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs_policy]
}




resource "aws_guardduty_detector" "icoach_guardduty" {
  enable = true
}


resource "aws_accessanalyzer_analyzer" "icoach_analyzer" {
  analyzer_name = "icoach-iam-access-analyzer"
  type          = "ACCOUNT"
}

resource "aws_securityhub_account" "icoach_security_hub" {
  enable_default_standards = true
}