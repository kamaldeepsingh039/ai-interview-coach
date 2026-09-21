resource "aws_cloudfront_origin_access_control" "static_assets" {
  name                              = "icoach-static-assets-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "static_assets" {
  enabled     = true
  price_class = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.cloudfront_static_assets.bucket_regional_domain_name
    origin_id                = "s3-icoach-static-assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.static_assets.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods          = ["GET", "HEAD"]
    target_origin_id        = "s3-icoach-static-assets"
    viewer_protocol_policy  = "redirect-to-https"
    cache_policy_id         = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Name = "icoach-static-assets-cdn" }
}









resource "aws_ssm_parameter" "questions_bank_url" {
  name  = "/icoach/questions-bank-url"
  type  = "String"
  value = "https://${aws_cloudfront_distribution.static_assets.domain_name}/data/questions.json"
}

resource "aws_iam_role_policy" "app_ssm_questions_bank" {
  name = "icoach-app-ssm-questions-bank"
  role = aws_iam_instance_profile.app_profile.role

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = aws_ssm_parameter.questions_bank_url.arn
      }
    ]
  })
}