resource "aws_iam_role" "web_role" {
  name = "icoach-web-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}



resource "aws_iam_role" "app_role" {
  name = "icoach-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}







resource "aws_iam_role_policy" "web_cloudwatch" {
  name = "icoach-web-cloudwatch-policy"
  role = aws_iam_role.web_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}





resource "aws_iam_role_policy" "app_permissions" {
  name = "icoach-app-permissions-policy"
  role = aws_iam_role.app_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn,
          aws_secretsmanager_secret.gemini_api_key.arn
        ]
      }
    ]
  })
}





resource "aws_iam_instance_profile" "app_profile" {
  name = "icoach-app-instance-profile"
  role = aws_iam_role.app_role.name
}

resource "aws_iam_instance_profile" "web_profile" {
  name = "icoach-web-instance-profile"
  role = aws_iam_role.web_role.name
}



resource "aws_iam_role_policy_attachment" "app_ssm_core" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}