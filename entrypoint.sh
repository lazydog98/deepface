#!/bin/bash

echo "=== DeepFace GPU Docker Container Starting ==="

# Check NVIDIA GPU availability
echo "Checking GPU availability..."
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader,nounits 2>/dev/null || echo "nvidia-smi command failed"
else
    echo "INFO: nvidia-smi not found - running in CPU-only mode"
fi

# Test TensorFlow GPU support
echo "Testing TensorFlow GPU support..."
python3 -c "
import os
import tensorflow as tf

# Suppress TensorFlow warnings for cleaner output
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'

print(f'TensorFlow version: {tf.__version__}')
print(f'CUDA built: {tf.test.is_built_with_cuda()}')

try:
    gpu_available = tf.test.is_gpu_available()
    print(f'GPU available: {gpu_available}')
    
    gpus = tf.config.list_physical_devices('GPU')
    print(f'Number of GPUs: {len(gpus)}')
    
    if gpus:
        for i, gpu in enumerate(gpus):
            print(f'GPU {i}: {gpu}')
            try:
                tf.config.experimental.set_memory_growth(gpu, True)
                print(f'Memory growth enabled for GPU {i}')
            except Exception as e:
                print(f'Could not set memory growth for GPU {i}: {e}')
        print('✓ GPU acceleration available')
    else:
        print('INFO: No GPUs detected - running on CPU')
except Exception as e:
    print(f'GPU check error: {e}')
    print('INFO: Continuing with CPU-only mode')
"

# Test DeepFace import and basic functionality
echo "Testing DeepFace module import..."
python3 -c "
import os
import sys
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'

print(f'Python path: {sys.path}')
print('Checking installed packages...')

try:
    import pkg_resources
    installed_packages = [d.project_name for d in pkg_resources.working_set]
    if 'deepface' in installed_packages:
        print('✓ DeepFace package found in installed packages')
    else:
        print('✗ DeepFace package not found in installed packages')
        print('Available packages:', [p for p in installed_packages if 'deep' in p.lower() or 'face' in p.lower()])
except Exception as e:
    print(f'Error checking packages: {e}')

try:
    import deepface
    from deepface import DeepFace
    print('✓ DeepFace imported successfully')
    
    # Test if DeepFace can detect GPU
    import tensorflow as tf
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        print('✓ DeepFace can access GPU acceleration')
    else:
        print('INFO: DeepFace running on CPU only')
        
except ImportError as e:
    print(f'✗ Failed to import DeepFace: {e}')
    print('Python sys.path:')
    for path in sys.path:
        print(f'  {path}')
    exit(1)
except Exception as e:
    print(f'✗ Error testing DeepFace: {e}')
    exit(1)
"

echo "=== Starting DeepFace API Server ==="

# Start the application
exec gunicorn --workers=1 --timeout=7200 --bind=0.0.0.0:5000 --log-level=info --access-logformat='%(h)s - - [%(t)s] "%(r)s" %(s)s %(b)s %(L)s' --access-logfile=- "app:create_app()"
