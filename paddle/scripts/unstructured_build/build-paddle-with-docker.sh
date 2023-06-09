#!/bin/bash

set -ex

# Clear previous build
rm -rf build > /dev/null 2>&1
# Use manylinux container to build wheel for maximum compatibility
docker pull quay.io/pypa/manylinux2014_aarch64
# Mount local unstructured.Paddle to container and build wheel
docker run -it --name build-paddle -v ./:/unstructured.Paddle quay.io/pypa/manylinux2014_aarch64 sh unstructured.Paddle/paddle/scripts/unstructured_build/build-paddle.sh
mv build/python/dist/unstructured.paddlepaddle-2.4.1-cp38-cp38-linux_aarch64.whl build/python/dist/unstructured.paddlepaddle-2.4.1-cp38-cp38-manylinux2014_aaarch64.whl
# TODO: push wheel to PyPI
# here is how to upload to testpypi (requires `pip install twine`):
# twine upload -r testpypi build/python/dist/unstructured.paddlepaddle-2.4.1-cp38-cp38-manylinux2014_aaarch64.whl