# ---------- BUILD STAGE ----------
FROM docker.io/nvidia/cuda:13.1.1-cudnn-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    clang \
    cmake \
    pkg-config \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Clone LTEngine
RUN git clone --recursive https://github.com/LibreTranslate/LTEngine.git .

# Build with CUDA support
ENV CUDAARCHS="75;80;86;89"
ENV CMAKE_ARGS="-DCMAKE_CUDA_ARCHITECTURES=86" 
#RTX 3090 → 86

RUN cargo build --release --features cuda
# ---------- RUNTIME STAGE ----------
FROM docker.io/nvidia/cuda:13.1.1-cudnn-runtime-ubuntu22.04



WORKDIR /app

RUN apt-get update && apt-get install -y \
    libstdc++6 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy binary
COPY --from=builder /app/target/release/ltengine /usr/local/bin/ltengine

EXPOSE 5050

# Default model
CMD ["ltengine", "-m", "gemma3-4b", "--n-gpu-layers", "99"]
