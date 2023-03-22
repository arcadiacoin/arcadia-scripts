#!/bin/bash

# Check for commands
command -v curl >/dev/null 2>&1 || { echo "Requires curl but it's not installed. If Ubuntu use apt-get install wget" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Requires jq but it's not installed. If Ubuntu use apt-get install jq" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Requires docker but it's not installed. Please install Docker before running this script." >&2; exit 1; }

# Variables
ARCADIA_DATA_DIR="$HOME/Arcadia/"
ARCADIA_HOST_DIR="$HOME"

# Stop existing node
if docker ps -a | grep -q arcadia; then
  docker stop arcadia
  docker rm arcadia
fi

# Create Arcadia's data directory
mkdir -p "$ARCADIA_DATA_DIR"

# Download the latest ledger snapshot
echo "Downloading latest ledger"
url="https://ledger.arcadiacoin.net/"
file=$(curl -s "$url" | grep -oE 'href="[^"]+"' | sed 's/href="//;s/"$//' | grep -E '.*\.ldb$' | tail -1)
wget --quiet --no-parent --accept='*.ldb' -r -l 1 -nd -N -P "$ARCADIA_DATA_DIR" "$url$file" -O "${ARCADIA_DATA_DIR}data.ldb"

# Get the most recent tag for arcadiacoin/arcadia
echo "Getting latest version"
TAG=$(curl -s "https://registry.hub.docker.com/v2/repositories/arcadiacoin/arcadia/tags/?page_size=1" | jq -r '.results[].name')

# Pull the most recent tag
echo "Downloading latest version"
docker pull arcadiacoin/arcadia:$TAG

# Run the arcadiacoin/arcadia container with the specified ports and volumes
echo "Starting Node"
docker run --restart=unless-stopped -d \
  -p 7245:7045 \
  -p 127.0.0.1:7246:7046 \
  -p 127.0.0.1:7248:7048 \
  -v ${ARCADIA_HOST_DIR}:/root \
  --name arcadia \
  arcadiacoin/arcadia:${TAG}

# Output result
if docker ps --format '{{.Names}}' | grep -q arcadia; then
  echo "Arcadia node is running"
  echo "Node address: 127.0.0.1:7046"
  echo ""
  echo "==="
  echo ""
  echo "Helpful commands"
  echo "Logs: docker logs arcadia"
  echo "Restart: docker restart arcadia"
else
  echo "Node is not running. There was a problem."
fi
