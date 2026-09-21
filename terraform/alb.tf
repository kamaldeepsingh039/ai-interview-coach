resource "aws_lb" "public_alb" {
  name               = "public-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_alb_sg.id]
  subnets            = [aws_subnet.public_web_subnet_a.id, aws_subnet.public_web_subnet_b.id]

  tags = {
    Name = "icoach-public-alb"
  }

}
resource "aws_lb_target_group" "web_tg" {
  name        = "web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.icoach_vpc.id
  target_type = "instance"

  health_check {
    path                = "/nginx-health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }
  tags = {
    Name = "icoach-web-tg"
  }

}

resource "aws_lb_listener" "public_alb_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }

}
resource "aws_lb" "internal_alb" {
  name               = "icoach-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb_sg.id]
  subnets            = [aws_subnet.private_app_subnet_a.id, aws_subnet.private_app_subnet_b.id]

  tags = {
    Name = "internal-alb"
  }

}

resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.icoach_vpc.id
  target_type = "instance"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30

  }
  tags = {
    Name = "icoach-app-tg"
  }
}

resource "aws_lb_listener" "internal_alb_listener" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

}