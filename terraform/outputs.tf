output "alb_dns_name" {
  value = aws_lb.public_alb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.icoach_db.endpoint
}



output "cloudfront_static_assets_domain_name" {
  description = "CloudFront domain serving static assets and question bank data"
  value       = aws_cloudfront_distribution.static_assets.domain_name
}

output "cloudfront_static_assets_distribution_id" {
  description = "Distribution ID, needed later for cache invalidations"
  value       = aws_cloudfront_distribution.static_assets.id
}