resource "aws_s3_bucket" "static_assets" {
  bucket = "icoach-project-static-s3"

  tags = {
    Name = "icoach-static-assets"
  }
}
resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}




resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "icoach-project-trail-s3"

  tags = {
    Name = "icoach-cloud-trail"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}









resource "aws_s3_bucket" "cloudfront_static_assets" {
  bucket = "icoach-static-assets-s3"
  tags   = { Name = "icoach-cloudfront-static-assets" }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_static_assets" {
  bucket                  = aws_s3_bucket.cloudfront_static_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudfront_static_assets" {
  bucket = aws_s3_bucket.cloudfront_static_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "cloudfront_static_assets_policy" {
  bucket = aws_s3_bucket.cloudfront_static_assets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.cloudfront_static_assets.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.static_assets.arn
          }
        }
      }
    ]
  })
}



# icoach-static-assets-s3  2 folder:- data (question.json) , static (scripts.js & style.css)