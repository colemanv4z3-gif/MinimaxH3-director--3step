FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Installazione dipendenze di sistema essenziali (incluso FFmpeg per la gestione video)
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    ffmpeg \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clonazione del repository ufficiale di ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI

WORKDIR /app/ComfyUI

# Installazione di PyTorch con supporto CUDA 12.4 (compatibile con GPU serie RTX 40/50)
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# Installazione dei requisiti base di ComfyUI
RUN pip3 install --no-cache-dir -r requirements.txt

# --- INSTALLAZIONE CUSTOM NODES PER MINIMAX H3 ---
WORKDIR /app/ComfyUI/custom_nodes

# 1. Nodi specifici H3 (Multishot e Motion Context Multi-Ref)
RUN git clone https://github.com/jlucasmcrell/ComfyUI-H3-Multishot.git && \
    git clone https://github.com/seitanism/ComfyUI-H3-Motion-Context-MultiRef.git

# 2. Utilità e supporto GGUF/Attention
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# Installazione dei requirements specifici dei custom nodes (gestendo eventuali errori non bloccanti)
RUN pip3 install --no-cache-dir -r ComfyUI-H3-Multishot/requirements.txt || true
RUN pip3 install --no-cache-dir -r ComfyUI-H3-Motion-Context-MultiRef/requirements.txt || true
RUN pip3 install --no-cache-dir -r ComfyUI-KJNodes/requirements.txt || true
RUN pip3 install --no-cache-dir -r ComfyUI-GGUF/requirements.txt || true
RUN pip3 install --no-cache-dir -r ComfyUI-Manager/requirements.txt || true

# Installazione di SageAttention per l'ottimizzazione della VRAM
RUN pip3 install --no-cache-dir sage-attention || true

# Esposizione della porta di default di ComfyUI
EXPOSE 8188

WORKDIR /app/ComfyUI

# Avvio di ComfyUI con ascolto su tutte le interfacce di rete
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
