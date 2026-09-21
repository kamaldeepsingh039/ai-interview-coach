resource "aws_sns_topic" "infra_alerts" {
  name = "icoach-alert"
}


resource "aws_sns_topic_subscription" "infra_alerts_email" {
  topic_arn = aws_sns_topic.infra_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}





resource "aws_cloudwatch_metric_alarm" "web_unhealthy_hosts" {
  alarm_name          = "web_unhealthy_instance"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 120
  statistic           = "Average"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.infra_alerts.arn]

  dimensions = {
    TargetGroup  = aws_lb_target_group.web_tg.arn_suffix
    LoadBalancer = aws_lb.public_alb.arn_suffix
  }
}






resource "aws_cloudwatch_metric_alarm" "app_unhealthy_hosts" {
  alarm_name          = "app_unhealthy_instance"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 120
  statistic           = "Average"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.infra_alerts.arn]

  dimensions = {
    TargetGroup  = aws_lb_target_group.app_tg.arn_suffix
    LoadBalancer = aws_lb.internal_alb.arn_suffix
  }
}






resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 4294967296
  alarm_actions       = [aws_sns_topic.infra_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.icoach_db.identifier
  }
}


resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_sns_topic.infra_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.icoach_db.identifier
  }
}