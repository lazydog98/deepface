#!/bin/bash

echo "=== DeepFace GPU Docker Container Starting ==="

echo "Checking GPU availability..."
if command -v nvidia-smi; then
    echo "NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader || echo "nvidia-smi failed"
else
    echo "INFO: nvidia-smi not found - CPU mode"
fi

echo "Testing TensorFlow GPU support..."
python3 -c "
import os
import tensorflow as tf

# Suppress some TensorFlow warnings for cleaner output
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'

print(f'TensorFlow version: {tf.__version__}')
print(f'CUDA built: {tf.test.is_built_with_cuda()}')

# Check GPU availability
gpus = tf.config.list_physical_devices('GPU')
print(f'Number of GPUs detected: {len(gpus)}')

if gpus:
    for i, gpu in enumerate(gpus):
        print(f'GPU {i}: {gpu}')
        try:
            # Enable memory growth to avoid allocating all GPU memory at once
            tf.config.experimental.set_memory_growth(gpu, True)
            print(f'Memory growth enabled for GPU {i}')
        except Exception as e:
            print(f'Could not set memory growth for GPU {i}: {e}')
    
    # Test actual GPU computation
    try:
        with tf.device('/GPU:0'):
            # Simple computation test
            a = tf.constant([[1.0, 2.0], [3.0, 4.0]])
            b = tf.constant([[1.0, 1.0], [0.0, 1.0]])
            c = tf.matmul(a, b)
            print(f'GPU computation test successful: {c.numpy().tolist()}')
            print('✓ TensorFlow GPU acceleration is WORKING')
    except Exception as e:
        print(f'GPU computation test failed: {e}')
        print('⚠ TensorFlow may fall back to CPU')
else:
    print('INFO: No GPUs detected - running on CPU only')
"

echo "Testing DeepFace with GPU support..."
python3 -c "
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'

try:
    import deepface
    from deepface import DeepFace
    print('✓ DeepFace imported successfully')
    
    # Check if DeepFace can access GPU
    import tensorflow as tf
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        print('✓ DeepFace can access GPU acceleration')
        print('✓ Face recognition models will use GPU when loaded')
    else:
        print('INFO: DeepFace running on CPU only')
        
except ImportError as e:
    print(f'✗ Failed to import DeepFace: {e}')
    exit(1)
except Exception as e:
    print(f'✗ Error testing DeepFace: {e}')
    exit(1)
"

echo "=== GPU Setup Complete - Starting DeepFace API Server ==="
exec gunicorn --workers=1 --timeout=7200 --bind=0.0.0.0:5000 --log-level=info "app:create_app()"