#!/bin/bash

set -ex

# Update the system and install dependencies
yum -y update
yum install -y epel-release
yum install -y bzip2
yum install -y make wget tar xz gcc

# Install gcc & g++ ≥ 8 for Python
yum -y install centos-release-scl
yum -y install devtoolset-9-gcc*
yum clean all

# Enable devtoolset-9 environment
source /opt/rh/devtoolset-9/enable

# Install Python
yum -y install openssl-devel bzip2-devel libffi-devel make git sqlite-devel
curl -O https://www.python.org/ftp/python/3.8.15/Python-3.8.15.tgz
tar -xzf Python-3.8.15.tgz
cd Python-3.8.15/
./configure --enable-optimizations
make altinstall
cd ..
rm -rf Python-3.8.15*
yum -y remove openssl-devel bzip2-devel libffi-devel make sqlite-devel
rm -rf /var/cache/yum/*
yum clean all

# Set up environment
export HOME="/home/"
mkdir -p ${HOME}/.ssh
chmod go-rwx ${HOME}/.ssh
ssh-keyscan -t rsa github.com >> ${HOME}/.ssh/known_hosts
export PYTHONPATH="${PYTHONPATH}:${HOME}"
export PATH="/home/usr/.local/bin:${PATH}"
export PADDLE_VERSION=2.4.1

# Install CMake and Patchelf
wget https://github.com/Kitware/CMake/archive/refs/tags/v3.16.9.tar.gz
tar -zxvf v3.16.9.tar.gz
rm v3.16.9.tar.gz
cd CMake-3.16.9
source /opt/rh/devtoolset-9/enable
yum install openssl openssl-devel -y
./bootstrap
gmake
cd /
wget http://nixos.org/releases/patchelf/patchelf-0.10/patchelf-0.10.tar.bz2
tar xf patchelf-0.10.tar.bz2
cd patchelf-0.10
./configure
make install

export PATH=/home/CMake-3.16.9/bin:$PATH
export PYTHON_LIBRARY="/usr/local/lib/python3.8"
export PYTHON_INCLUDE_DIRS="/usr/local/include/python3.8"

# Install pip, numpy, wheel, and protobuf
python3.8 -m pip install pip==22.2.1
pip install --no-cache numpy wheel protobuf

# build paddle from mounted unstructured.Paddle
cd /unstructured.Paddle
mkdir build
cd build
PYTHON_EXECUTABLE=/usr/local/bin/python3.8 cmake .. -DPY_VERSION=3.8 -DPYTHON_INCLUDE_DIR=${PYTHON_INCLUDE_DIRS} \
    -DPYTHON_LIBRARY=${PYTHON_LIBRARY} -DWITH_GPU=OFF -DWITH_AVX=OFF -DWITH_ARM=ON
make -j$(nproc)

