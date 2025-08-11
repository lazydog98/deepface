#!/bin/bash

echo "=== DeepFace GPU Docker Test Script ==="

# Build the Docker image
echo "Building Docker image..."
docker build -t deepface-rest-gpu:latest .

if [ $? -ne 0 ]; then
    echo "✗ Docker build failed"
    exit 1
fi

echo "✓ Docker build successful"

# Test basic imports (simulating GitHub Actions environment)
echo "=== Testing basic imports (CI/CD simulation) ==="
timeout 60 docker run --rm deepface-rest-gpu:latest python3 -c "
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'
import tensorflow as tf
import deepface
print('✓ Basic imports successful')
print(f'TensorFlow version: {tf.__version__}')
print(f'CUDA built: {tf.test.is_built_with_cuda()}')
print(f'GPU available: {tf.test.is_gpu_available()}')
"

# Test with GPU (if available)
if command -v nvidia-smi &> /dev/null; then
    echo "=== Testing container with GPU ==="
    timeout 60 docker run --rm --gpus all deepface-rest-gpu:latest python3 -c "
    import os
    os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'
    import tensorflow as tf
    import deepface
    print('✓ GPU-enabled container test')
    print(f'TensorFlow version: {tf.__version__}')
    print(f'GPU available: {tf.test.is_gpu_available()}')
    gpus = tf.config.list_physical_devices('GPU')
    print(f'Number of GPUs detected: {len(gpus)}')
    "
else
    echo "INFO: nvidia-smi not found - skipping GPU test (normal for CI/CD)"
fi

# Test entrypoint startup (simulating GitHub Actions test)
echo "=== Testing entrypoint startup ==="
docker run -d --name deepface-gpu-test deepface-rest-gpu:latest

sleep 15

echo "=== Container startup logs ==="
docker logs deepface-gpu-test 2>&1 | head -30

if docker ps --filter "name=deepface-gpu-test" --format "table {{.Names}}\t{{.Status}}" | grep -q "deepface-gpu-test"; then
    echo "✓ Container started successfully and is running"
else
    echo "✗ Container failed to start or crashed"
    docker logs deepface-gpu-test
    docker stop deepface-gpu-test 2>/dev/null || true
    docker rm deepface-gpu-test 2>/dev/null || true
    exit 1
fi

# Cleanup
docker stop deepface-gpu-test
docker rm deepface-gpu-test

echo "=== All tests completed successfully - ready for GitHub Actions ==="