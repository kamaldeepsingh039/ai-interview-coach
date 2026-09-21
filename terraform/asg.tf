resource "aws_launch_template" "web_lt" {
  name_prefix   = "icoach-web-lt"
  image_id      = var.web_ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.web_profile.name
  }

  network_interfaces {
    security_groups = [aws_security_group.web_sg.id]
  }


  user_data = base64encode(templatefile("${path.module}/web_user_data.sh.tpl", {
    internal_alb_dns = aws_lb.internal_alb.dns_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "icoach-web-instance"
    }
  }
}





resource "aws_autoscaling_group" "web_asg" {
  name                      = "icoach-web-asg"
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.public_web_subnet_a.id, aws_subnet.public_web_subnet_b.id]
  target_group_arns         = [aws_lb_target_group.web_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "icoach-web-instance"
    propagate_at_launch = true

  }

}


resource "aws_launch_template" "app_lt" {
  name_prefix   = "icoach-app-lt"
  image_id      = var.app_ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }



  network_interfaces {

    security_groups = [aws_security_group.app_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "icoach-app-instance"
    }
  }
}




resource "aws_autoscaling_group" "app_asg" {
  name                      = "icoach-app-asg"
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.private_app_subnet_a.id, aws_subnet.private_app_subnet_b.id]
  target_group_arns         = [aws_lb_target_group.app_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300


  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "icoach-app-instance"
    propagate_at_launch = true
  }

}