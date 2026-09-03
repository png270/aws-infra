data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "AllowEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${var.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.name_prefix}-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.instance.name
}

resource "aws_security_group" "instance" {
  name        = "${var.name_prefix}-ec2-sg"
  description = "No inbound access; restricted outbound access for SSM"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-ec2-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.instance.id

  description = "Allow outbound HTTPS for AWS APIs and SSM"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "dns_udp" {
  security_group_id = aws_security_group.instance.id

  description = "Allow DNS queries within the VPC"
  ip_protocol = "udp"
  from_port   = 53
  to_port     = 53
  cidr_ipv4   = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "dns_tcp" {
  security_group_id = aws_security_group.instance.id

  description = "Allow fallback DNS queries over TCP"
  ip_protocol = "tcp"
  from_port   = 53
  to_port     = 53
  cidr_ipv4   = var.vpc_cidr
}

resource "aws_instance" "this" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.instance.id
  ]

  iam_instance_profile = aws_iam_instance_profile.this.name

  monitoring                           = false
  source_dest_check                    = true
  instance_initiated_shutdown_behavior = "stop"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    encrypted             = true
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail

    systemctl disable --now sshd || true

    cat > /etc/issue <<'BANNER'
    Authorized access only.
    This system is managed through AWS Systems Manager.
    Interactive SSH access is disabled.
    BANNER

    systemctl enable --now amazon-ssm-agent
  EOT

  user_data_replace_on_change = true

  tags = {
    Name = "${var.name_prefix}-ec2"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm_core
  ]
}

data "aws_iam_policy_document" "s3_application_access" {
  statement {
    sid    = "ReadBucketLocation"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation"
    ]

    resources = [
      var.data_bucket_arn
    ]
  }

  statement {
    sid    = "ListApplicationPrefix"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      var.data_bucket_arn
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "application",
        "application/*"
      ]
    }
  }

  statement {
    sid    = "ReadWriteApplicationObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${var.data_bucket_arn}/application/*"
    ]
  }
}

resource "aws_iam_policy" "s3_application_access" {
  name        = "${var.name_prefix}-s3-application-access"
  description = "Least-privilege access to the application prefix in the project data bucket"
  policy      = data.aws_iam_policy_document.s3_application_access.json

  tags = {
    Name = "${var.name_prefix}-s3-application-access"
  }
}

resource "aws_iam_role_policy_attachment" "s3_application_access" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.s3_application_access.arn
}