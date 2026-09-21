resource "aws_security_group" "public_alb_sg" {
  name        = "public_alb_sg"
  description = "Public ALB - accepts HTTP from the internet"
  vpc_id      = aws_vpc.icoach_vpc.id
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    description = "allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "icoach-public-alb-sg"
  }
}
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "web tier (nginx)- accepts http from the public ALB only"
  vpc_id      = aws_vpc.icoach_vpc.id

  ingress {
    description     = "HTTP from public alb only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_alb_sg.id]
  }

  egress {
    description = "allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "icoach-web-sg"
  }
}

resource "aws_security_group" "internal_alb_sg" {
  name        = "internal_alb_sg"
  description = "internal ALB- accepts HTTP from web sg only"
  vpc_id      = aws_vpc.icoach_vpc.id

  ingress {
    description     = "accepts HTTP from web sg"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
  egress {
    description = "allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "icoach-internal-alb-sg"
  }
}
resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "app tier - accepts HTTP from internal ALB"
  vpc_id      = aws_vpc.icoach_vpc.id

  ingress {
    description     = "accepts HTTP from internal ALB"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb_sg.id]
  }

  egress {
    description = "allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "icoach-app-sg"
  }

}

resource "aws_security_group" "data_sg" {
  name        = "data_sg"
  description = "data tier (rds) - only accepts PostgreSQL from app sg"
  vpc_id      = aws_vpc.icoach_vpc.id

  ingress {
    description     = "Accepts PostgreSQL traffic only from app sg"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  egress {
    description = "allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "icoach-data-sg"
  }

}