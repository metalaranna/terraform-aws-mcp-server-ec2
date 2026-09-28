provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        Project   = var.name
        ManagedBy = "terraform"
      },
      var.tags
    )
  }
}

# Latest Amazon Linux 2023 AMI, resolved through the public SSM parameter.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ---------------------------------------------------------------------------
# IAM: SSM Session Manager access, so no SSH key or open port 22 is needed.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-profile"
  role = aws_iam_role.this.name
}

# ---------------------------------------------------------------------------
# Network: only the CIDRs you list can reach the MCP port.
# ---------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "Access to the MCP server"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "mcp" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.this.id
  description       = "MCP server from ${each.value}"
  ip_protocol       = "tcp"
  from_port         = var.mcp_port
  to_port           = var.mcp_port
  cidr_ipv4         = each.value
}

# HTTPS out only: package repos, Docker Hub, Terraform Registry, SSM.
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.this.id
  description       = "HTTPS to the internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------------------------------------------------------------------------
# Compute
# ---------------------------------------------------------------------------
resource "aws_instance" "mcp" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = var.associate_public_ip

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    mcp_image = var.mcp_image
    mcp_port  = var.mcp_port
  })
  user_data_replace_on_change = true

  # IMDSv2 only.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size_gb
    encrypted   = true
  }

  tags = {
    Name = var.name
  }
}
