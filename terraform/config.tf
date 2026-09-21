resource "aws_iam_role" "config_role" {
  name = "icoach-iam-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}



resource "aws_iam_role_policy_attachment" "config_role_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}



resource "aws_config_configuration_recorder" "icoach_recorder" {
  name     = "icoach-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
  }
}




resource "aws_config_delivery_channel" "icoach_delivery" {
  name           = "icoach-config-logs-delivery"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id

  depends_on = [aws_config_configuration_recorder.icoach_recorder]
}



resource "aws_config_configuration_recorder_status" "icoach_recorder_status" {
  name       = aws_config_configuration_recorder.icoach_recorder.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.icoach_delivery]
}