#!/bin/bash

echo "=== DeepFace GPU Docker Container Starting ==="

echo "Checking GPU availability..."
if command -v nvidia-smi; then
    echo "NVIDIA GPU detected"
    nvidia-smi --query-gpu=name --format=csv,noheader || echo "nvidia-smi failed"
else
    echo "INFO: nvidia-smi not found - CPU mode"
fi

echo "Testing TensorFlow..."
python3 -c "import tensorflow as tf; print('TensorFlow version:', tf.__version__)"

echo "Testing DeepFace..."
python3 -c "import deepface; print('DeepFace imported successfully')"

echo "=== Starting DeepFace API Server ==="
exec gunicorn --workers=1 --timeout=7200 --bind=0.0.0.0:5000 --log-level=info "app:create_app()"