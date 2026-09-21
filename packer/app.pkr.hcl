packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "amazon-ebs" "app_ami" {
  region        = "us-east-1"
  instance_type = "t3.micro"
  ssh_username  = "ec2-user"
  ami_name      = "icoach-app-ami-{{timestamp}}"

  source_ami_filter {
    filters = {
      name = "al2023-ami-2023.*-x86_64"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = 20
    volume_type = "gp3"
  }
}

build {
  name    = "icoach-app-build"
  sources = ["source.amazon-ebs.app_ami"]

  provisioner "ansible" {
    playbook_file = "../ansible/app.yml"
  }
}