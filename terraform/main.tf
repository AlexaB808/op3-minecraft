terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Use the default VPC instead of creating a new one
data "aws_vpc" "default" {
  default = true
}

# Look up the latest Ubuntu 22.04 LTS AMI published by Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for the Minecraft server
resource "aws_security_group" "minecraft" {
  name        = "minecraft-sg"
  description = "SSH admin access and Minecraft client connections"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH admin access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  ingress {
    description = "Minecraft clients"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "minecraft-sg"
  }
}

# Minecraft EC2 instance
resource "aws_instance" "minecraft" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.minecraft.id]
  iam_instance_profile        = "LabInstanceProfile"
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    delete_on_termination = true
  }

  # Install Ansible and Git so the playbook can run on first boot
  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y ansible git
  EOF

  tags = {
    Name = "minecraft-server"
  }
}

# Chain Terraform into Ansible after provisioning
resource "null_resource" "ansible_provision" {
  triggers = {
    instance_id = aws_instance.minecraft.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for SSH to be ready..."
      sleep 60
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        -i "${aws_instance.minecraft.public_ip}," \
        --private-key ~/Desktop/sys_admin/${var.key_name}.pem \
        -u ubuntu \
        ../ansible/playbook.yml
    EOT
  }

  depends_on = [aws_instance.minecraft]
}
