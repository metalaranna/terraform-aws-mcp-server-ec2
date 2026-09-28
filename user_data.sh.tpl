#!/bin/bash
# Bootstraps Docker and runs the Terraform MCP server as a systemd service.
set -euxo pipefail

dnf install -y docker
systemctl enable --now docker

cat > /etc/systemd/system/terraform-mcp-server.service <<'UNIT'
[Unit]
Description=Terraform MCP Server (streamable-http)
After=docker.service
Requires=docker.service

[Service]
Restart=always
RestartSec=5
ExecStartPre=-/usr/bin/docker rm -f terraform-mcp-server
ExecStartPre=/usr/bin/docker pull ${mcp_image}
ExecStart=/usr/bin/docker run --rm --name terraform-mcp-server \
  -p ${mcp_port}:${mcp_port} \
  -e TRANSPORT_MODE=streamable-http \
  -e TRANSPORT_HOST=0.0.0.0 \
  -e TRANSPORT_PORT=${mcp_port} \
  -e MCP_ENDPOINT=/mcp \
  -e LOG_FORMAT=json \
  ${mcp_image}
ExecStop=/usr/bin/docker stop terraform-mcp-server

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now terraform-mcp-server

# Wait for the health endpoint so failures show up in the cloud-init log.
for attempt in $(seq 1 30); do
  if curl -fsS "http://localhost:${mcp_port}/health"; then
    break
  fi
  sleep 5
done
