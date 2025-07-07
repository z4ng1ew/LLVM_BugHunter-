# Multi-stage Dockerfile for LLVM Fuzzing Project
FROM ubuntu:20.04 AS builder

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    python3 \
    python3-pip \
    llvm-12-dev \
    clang-12 \
    libclang-12-dev \
    libc++-12-dev \
    libc++abi-12-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up LLVM environment
ENV LLVM_CONFIG=llvm-config-12
ENV CC=clang-12
ENV CXX=clang++-12

# Create symbolic links for convenience
RUN ln -s /usr/bin/llvm-config-12 /usr/bin/llvm-config && \
    ln -s /usr/bin/clang-12 /usr/bin/clang && \
    ln -s /usr/bin/clang++-12 /usr/bin/clang++ && \
    ln -s /usr/bin/opt-12 /usr/bin/opt

# Set working directory
WORKDIR /workspace

# Copy project files
COPY . /workspace/

# Make scripts executable
RUN chmod +x scripts/*.sh

# Build the project
RUN ./scripts/build.sh

# Verify build
RUN ls -la build/ && \
    ./build/llvm_example > /tmp/test_output.txt && \
    cat /tmp/test_output.txt

# Runtime stage
FROM ubuntu:20.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    llvm-12 \
    clang-12 \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd -m -s /bin/bash fuzzer && \
    mkdir -p /home/fuzzer/workspace && \
    chown -R fuzzer:fuzzer /home/fuzzer

# Copy built artifacts from builder stage
COPY --from=builder /workspace/build /home/fuzzer/workspace/build
COPY --from=builder /workspace/scripts /home/fuzzer/workspace/scripts
COPY --from=builder /workspace/examples /home/fuzzer/workspace/examples
COPY --from=builder /workspace/tests /home/fuzzer/workspace/tests

# Set up environment for fuzzer user
USER fuzzer
WORKDIR /home/fuzzer/workspace

# Create directories for fuzzing
RUN mkdir -p corpus crashes reports

# Set up LLVM environment
ENV LLVM_CONFIG=llvm-config-12
ENV CC=clang-12
ENV CXX=clang++-12

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ./build/llvm_example > /dev/null || exit 1

# Default command
CMD ["./scripts/run_fuzzing.sh", "basic", "-t", "300"]

# Labels for metadata
LABEL maintainer="fuzzing-engineer@example.com"
LABEL description="LLVM Fuzzing Development Environment"
LABEL version="1.0"
LABEL org.opencontainers.image.title="LLVM Fuzzing Project"
LABEL org.opencontainers.image.description="Container for LLVM-based fuzzing development"
LABEL org.opencontainers.image.source="https://github.com/your-username/llvm-fuzzing-project"

# Expose port for potential web interface (future feature)
EXPOSE 8080

# Volume for persistent data
VOLUME ["/home/fuzzer/workspace/corpus", "/home/fuzzer/workspace/crashes", "/home/fuzzer/workspace/reports"]
