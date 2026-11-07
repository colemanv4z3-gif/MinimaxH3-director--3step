# Dockerfile for ComfyUI Video LTX Minimax on RunPod with RTX 5090
FROM nvidia/cuda:12.4-devel-ubuntu22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    wget \
    curl \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy ComfyUI source code
COPY ComfyUI-Video-LTX_Minimax/ComfyUI-Easy-Install/ComfyUI-Easy-Install/ComfyUI/ /app/ComfyUI

# Copy python_embeded directory
COPY ComfyUI-Video-LTX_Minimax/ComfyUI-Easy-Install/ComfyUI-Easy-Install/python_embeded/ /app/python_embeded

# Set environment variables
ENV PYTHONPATH=/app/ComfyUI
ENV PATH=/app/python_embeded/bin:$PATH

# Install Python dependencies
RUN pip3 install --no-cache-dir -r /app/ComfyUI/requirements.txt

# Create necessary directories
RUN mkdir -p /app/ComfyUI/input /app/ComfyUI/output /app/ComfyUI/models /app/ComfyUI/custom_nodes

# Copy custom nodes (OTTIMIZATO)
# Copia solo i custom nodes necessari per i workflow minimax LTX
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git /app/ComfyUI/custom_nodes/ComfyUI-Impact-Pack 2>/dev/null || true
RUN git clone https://github.com/guangzhengliang/ComfyUI-UltimateSDUpscaleGuider_H3.git /app/ComfyUI/custom_nodes/ComfyUI-UltimateSDUpscaleGuider_H3 2>/dev/null || true
RUN git clone https://github.com/Efficient-Motion-Fields/ComfyUI-H3-Motion-Context-MultiRef.git /app/ComfyUI/custom_nodes/ComfyUI-H3-Motion-Context-MultiRef 2>/dev/null || true
RUN git clone https://github.com/kijai/ComfyUI-Crystools.git /app/ComfyUI/custom_nodes/ComfyUI-Crystools 2>/dev/null || true
RUN git clone https://github.com/ltdrdata/ComfyUI-VideoHelperSuite.git /app/ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite 2>/dev/null || true
RUN git clone https://github.com/comfyanonymous/ComfyUI-MinimaxH3-Preview.git /app/ComfyUI/custom_nodes/ComfyUI-MiniMaxH3-Preview 2>/dev/null || true
RUN git clone https://github.com/kijai/ComfyUI-WarpedToolset.git /app/ComfyUI/custom_nodes/ComfyUI-WarpedToolset 2>/dev/null || true

# Copy specific custom node files needed for workflows
COPY "C:/Users/simon/Desktop/Aria pura/Workflow minimah Personalizzati Mini Max H3/muse_latent_io.py" /app/ComfyUI/custom_nodes/muse_latent_io.py
RUN chmod +x /app/ComfyUI/custom_nodes/muse_latent_io.py

# Copy startup script
COPY start_comfyui-ltx.sh /app/start_comfyui-ltx.sh
RUN chmod +x /app/start_comfyui-ltx.sh

# Expose port
EXPOSE 8188

# Default command
CMD ["/app/start_comfyui-ltx.sh"]