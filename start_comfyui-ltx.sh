#!/bin/bash

# Set up environment variables for ComfyUI Video LTX Minimax
export PYTHONPATH=/app/ComfyUI
export PATH=/app/python_embeded/bin:$PATH

# Create necessary directories if they don't exist
mkdir -p /app/ComfyUI/input /app/ComfyUI/output /app/ComfyUI/models /app/ComfyUI/custom_nodes

# Set model paths
echo "models: /app/ComfyUI/models" > /app/ComfyUI/extra_model_paths.yaml
echo "input: /app/ComfyUI/input" >> /app/ComfyUI/extra_model_paths.yaml
echo "output: /app/ComfyUI/output" >> /app/ComfyUI/extra_model_paths.yaml

# Copy the customized muse_minimax_refiner_v2.py from workflow directory
# This is a customized version from director 1.2 package
mkdir -p /app/ComfyUI/custom_nodes/muse_minimax
cp "C:/Users/simon/Desktop/Aria pura/Workflow minimah Personalizzati Mini Max H3/muse_minimax_refine_v2.py" /app/ComfyUI/custom_nodes/muse_minimax/muse_minimax_refiner_v2.py
chmod +x /app/ComfyUI/custom_nodes/muse_minimax/muse_minimax_refiner_v2.py

# Verify custom nodes
echo "=== Custom Nodes Installati ==="
ls -la /app/ComfyUI/custom_nodes/
echo ""

# Start ComfyUI with GPU support
echo "🚀 Avvio ComfyUI Video LTX Minimax..."
cd /app/ComfyUI
python3 main.py --listen 0.0.0.0 --port 8188 --enable-cors-header
