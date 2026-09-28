variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix applied to all resources."
  type        = string
  default     = "terraform-mcp-server"
}

variable "vpc_id" {
  description = "ID of the VPC to deploy into."
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for the instance. Must be a public subnet if you want a public IP."
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the MCP server (for example your office or home IP as x.x.x.x/32)."
  type        = list(string)

  validation {
    condition     = length(var.allowed_cidr_blocks) > 0 && !contains(var.allowed_cidr_blocks, "0.0.0.0/0")
    error_message = "Provide at least one CIDR block, and do not open the MCP server to 0.0.0.0/0."
  }
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.small"
}

variable "root_volume_size_gb" {
  description = "Size of the encrypted root volume in GiB."
  type        = number
  default     = 20
}

variable "associate_public_ip" {
  description = "Whether to assign a public IP address to the instance."
  type        = bool
  default     = true
}

variable "mcp_image" {
  description = "Container image for the MCP server. Pin a version tag rather than using latest."
  type        = string
  default     = "hashicorp/terraform-mcp-server:1.3.0"
}

variable "mcp_port" {
  description = "Port the MCP server listens on."
  type        = number
  default     = 8080
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
