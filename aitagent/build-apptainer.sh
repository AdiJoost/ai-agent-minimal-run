#!/bin/bash

set -e

AITAGENT_VERSION=${1:?"Usage: $0 <aitagent-version> <ait-mcp-version>"}
AIT_MCP_VERSION=${2:?"Usage: $0 <aitagent-version> <ait-mcp-version>"}

# Create directories for persistent volumes
mkdir -p ./volumes/ollama-data
mkdir -p ./apptainerdata/aitagent

# Convert docker images to SIF files (if not already done)
echo "Pulling and converting Docker images to SIF..."

# Disable cache explicitly for each build
echo "Building Ollama image..."
SINGULARITY_DISABLE_CACHE=True apptainer build --force ollama.sif docker://ollama/ollama

echo "Building aitagent image..."
SINGULARITY_DISABLE_CACHE=True apptainer build --force aitagent.sif docker://ajoostham/aitagent:${AITAGENT_VERSION}

echo "Building ait-mcp image..."
SINGULARITY_DISABLE_CACHE=True apptainer build --force ait-mcp.sif docker://ajoostham/ait-mcp:${AIT_MCP_VERSION}