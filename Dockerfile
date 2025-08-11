# 🧠 Base image with TensorFlow + CUDA + cuDNN preinstalled
FROM tensorflow/tensorflow:2.14.0-gpu

LABEL org.opencontainers.image.source https://github.com/serengil/deepface

# -----------------------------------
# Create required folders
RUN mkdir -p /app/deepface && chown -R 1001:0 /app

# -----------------------------------
# Switch to application directory
WORKDIR /app

# -----------------------------------
# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsm6 \
    libxext6 \
    libhdf5-dev \
    libboost-all-dev \
    cmake \
    libopenblas-dev \
    libatlas-base-dev \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------
# Copy DeepFace source and config files
COPY ./deepface /app/deepface
COPY ./requirements.txt /app/requirements.txt
COPY ./requirements_local /app/requirements_local.txt
COPY ./package_info.json /app/
COPY ./setup.py /app/
COPY ./README.md /app/
COPY ./entrypoint.sh /app/deepface/api/src/entrypoint.sh

# -----------------------------------
# Upgrade pip
RUN python3 -m pip install --upgrade pip

# 🧹 Filter out tensorflow from requirements_local.txt to avoid conflicts
RUN grep -v "tensorflow" /app/requirements_local.txt > /app/requirements_gpu.txt && \
    pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host=files.pythonhosted.org -r /app/requirements_gpu.txt

# 🧠 Install DeepFace from source without re-installing dependencies
RUN pip install --no-deps -e .

# Optional: Face anti-spoofing
RUN pip install torch==2.1.2

# Optional: Extra packages
RUN pip install cmake==3.24.1.1 dlib==19.20.0 lightgbm==2.3.1

# -----------------------------------
# Environment variables
ENV PYTHONUNBUFFERED=1

# -----------------------------------
# Expose port and run app
WORKDIR /app/deepface/api/src
EXPOSE 5000
ENTRYPOINT [ "sh", "entrypoint.sh" ]
