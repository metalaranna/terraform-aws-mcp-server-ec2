output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.mcp.id
}

output "public_ip" {
  description = "Public IP address of the instance (null if no public IP)."
  value       = aws_instance.mcp.public_ip
}

output "mcp_endpoint" {
  description = "MCP endpoint URL to register with your MCP client."
  value       = try("http://${aws_instance.mcp.public_ip}:${var.mcp_port}/mcp", null)
}

output "health_url" {
  description = "Health check URL."
  value       = try("http://${aws_instance.mcp.public_ip}:${var.mcp_port}/health", null)
}

output "ssm_session_command" {
  description = "Command to open a shell on the instance without SSH."
  value       = "aws ssm start-session --target ${aws_instance.mcp.id} --region ${var.region}"
}
