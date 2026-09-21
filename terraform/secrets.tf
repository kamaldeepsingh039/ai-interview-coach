resource "aws_secretsmanager_secret" "db_credentials" {
  name = "icoach/db-credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    DB_HOST     = aws_db_instance.icoach_db.address
    DB_PORT = tostring(aws_db_instance.icoach_db.port)
    DB_NAME     = aws_db_instance.icoach_db.db_name
    DB_USER     = aws_db_instance.icoach_db.username
    DB_PASSWORD = random_password.db_password.result
  })
}




resource "aws_secretsmanager_secret" "gemini_api_key" {
  name = "icoach/gemini-api-key"
}

resource "aws_secretsmanager_secret_version" "gemini_api_key" {
  secret_id = aws_secretsmanager_secret.gemini_api_key.id

  secret_string = jsonencode({
    GEMINI_API_KEY = var.gemini_api_key
  })
}