locals {
  instance_family  = split(".", var.instance_type)[0]
  ami_architecture = endswith(local.instance_family, "g") ? "arm64" : "x86_64"
  ssm_endpoint_services = {
    ssm         = "com.amazonaws.${data.aws_region.current.name}.ssm"
    ec2messages = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
    ssmmessages = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  }
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

data "aws_region" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-*-server-*"]
  }

  filter {
    name   = "architecture"
    values = [local.ami_architecture]
  }
}

resource "aws_security_group" "instance" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Private-first security group"
  vpc_id      = data.aws_subnet.selected.vpc_id

  dynamic "ingress" {
    for_each = var.ssh_ingress_cidr == "" ? [] : [var.ssh_ingress_cidr]
    content {
      description = "SSH from operator CIDR"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_security_group" "vpce" {
  count = var.enable_ssm_vpc_endpoints ? 1 : 0

  name        = "${var.project_name}-${var.environment}-vpce-sg"
  description = "Allow HTTPS from EC2 to SSM VPC endpoints"
  vpc_id      = data.aws_subnet.selected.vpc_id

  ingress {
    description     = "HTTPS from EC2 security group"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.instance.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpce-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = var.enable_ssm_vpc_endpoints ? local.ssm_endpoint_services : {}

  vpc_id              = data.aws_subnet.selected.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [data.aws_subnet.selected.id]
  security_group_ids  = [aws_security_group.vpce[0].id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.key}-vpce"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = var.associate_public_ip_address
  subnet_id                   = data.aws_subnet.selected.id
  vpc_security_group_ids      = [aws_security_group.instance.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  key_name                    = var.key_name != "" ? var.key_name : null
  user_data                   = var.cloud_init_user_data != "" ? var.cloud_init_user_data : null
  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = var.volume_size_gb
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  lifecycle {
    precondition {
      condition = (
        var.enable_ssm_vpc_endpoints ||
        (var.associate_public_ip_address && var.key_name != "" && var.ssh_ingress_cidr != "")
      )
      error_message = "Set SSM endpoints, or enable public IP with both key_name and ssh_ingress_cidr for SSH access."
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2"
    Project     = var.project_name
    Environment = var.environment
  }
}
