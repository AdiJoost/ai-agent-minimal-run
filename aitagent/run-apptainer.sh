#!/bin/bash

FILE_OFFSET=${1:?"Usage: $0 <FILE_OFFSET> <FILE_OFFSET_END>"}
FILE_OFFSET_END=${2:?"Usage: $0 <FILE_OFFSET> <FILE_OFFSET_END>"}

echo "Using FILE_OFFSET=$FILE_OFFSET"
echo "Using FILE_OFFSET_END=$FILE_OFFSET_END"

export FILE_OFFSET
export FILE_OFFSET_END

HOST_IP=$(ip route get 1 | awk '{print $7; exit}')

export OLLAMA_HOST="http://${HOST_IP}:11434"
export MCP_HOST="http://${HOST_IP}:8000"

echo "Detected host IP: $HOST_IP"
echo "Using OLLAMA_HOST=$OLLAMA_HOST"
echo "Using MCP_HOST=$MCP_HOST"

set -e

# Create directories for persistent volumes
mkdir -p ./volumes/ollama-data
mkdir -p ./apptainerdata/aitagent

# Cleanup function to stop all background processes
cleanup() {
  echo "Shutting down services..."
  kill $OLLAMA_PID $AIT_MCP_PID 2>/dev/null
  wait $OLLAMA_PID $AIT_MCP_PID 2>/dev/null || true
  echo "Cleanup complete"
}
trap cleanup EXIT

# Get absolute path to the directory (where this script is)
AITAGENT_DIR="$(cd "$(dirname "$0")"; pwd)"

echo "Starting Ollama..."
# --nv exposes NVIDIA GPUs allocated by Slurm (via CUDA_VISIBLE_DEVICES)
apptainer exec \
  --bind "$(pwd)/volumes/ollama-data:/root/.ollama" \
  --env OLLAMA_MODELS=/root/.ollama/models \
  --env CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-all}" \
  --env OLLAMA_NUM_GPU=999 \
  --nv \
  ollama.sif \
  ollama serve > /dev/null 2>&1 &

OLLAMA_PID=$!

echo "Starting ait-mcp..."
apptainer exec \
  --env-file "$AITAGENT_DIR/.env" \
  --pwd /ait-mcp \
  ait-mcp.sif \
  python run.py > /dev/null 2>&1 &

AIT_MCP_PID=$!

sleep 5

echo "Starting aitagent..."
apptainer exec \
  --env OLLAMA_HOST=$OLLAMA_HOST \
  --env MCP_HOST=$MCP_HOST \
  --env FILE_OFFSET=$FILE_OFFSET \
  --env FILE_OFFSET_END=$FILE_OFFSET_END \
  --env-file "$AITAGENT_DIR/.env" \
  --bind "$AITAGENT_DIR/data:/aitagent/data" \
  --bind "$AITAGENT_DIR/config:/aitagent/config" \
  --bind "$AITAGENT_DIR/logs:/aitagent/logs" \
  --pwd /aitagent \
  aitagent.sif \
  python run.py