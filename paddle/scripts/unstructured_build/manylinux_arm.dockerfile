# syntax=docker/dockerfile:experimental

# This image is based on the manylinux2014 image, which is based on CentOS 7.
# https://github.com/pypa/manylinux
FROM quay.io/pypa/manylinux2014_aarch64

ARG PIP_VERSION=22.2.1

RUN yum -y update && \
    yum install -y epel-release && \
    yum install -y bzip2 && \
    yum install -y make wget tar xz gcc 

# Install gcc & g++ ≥ 8 for Python
RUN yum -y install centos-release-scl && \
  yum -y install devtoolset-9-gcc* && \
  yum clean all

SHELL [ "/usr/bin/scl", "enable", "devtoolset-9"]

# Install Python
RUN yum -y install openssl-devel bzip2-devel libffi-devel make git sqlite-devel && \
  curl -O https://www.python.org/ftp/python/3.8.15/Python-3.8.15.tgz && tar -xzf Python-3.8.15.tgz && \
  cd Python-3.8.15/ && ./configure --enable-optimizations && make altinstall && \
  cd .. && rm -rf Python-3.8.15* && \
  ln -s /usr/local/bin/python3.8 /usr/local/bin/python3 && \
  $sudo yum -y remove openssl-devel bzip2-devel libffi-devel make sqlite-devel && \
  $sudo rm -rf /var/cache/yum/* && \
  yum clean all

# Set up environment 
ENV HOME /home/
# WORKDIR ${HOME}
RUN mkdir ${HOME}/.ssh && chmod go-rwx ${HOME}/.ssh \
  &&  ssh-keyscan -t rsa github.com >> /home/.ssh/known_hosts
ENV PYTHONPATH="${PYTHONPATH}:${HOME}"
ENV PATH="/home/usr/.local/bin:${PATH}"
ENV PADDLE_VERSION=2.4.2

# Install CMake (for building PaddlePaddle) and Patchelf (for building ManyLinux wheels)
RUN wget https://github.com/Kitware/CMake/archive/refs/tags/v3.16.9.tar.gz && \
    tar -zxvf v3.16.9.tar.gz && \
    rm v3.16.9.tar.gz && \
    cd CMake-3.16.9 && \
    scl enable devtoolset-9 bash && \
    yum install openssl openssl-devel -y && \
    ./bootstrap && \
    gmake && \
    cd /; wget http://nixos.org/releases/patchelf/patchelf-0.10/patchelf-0.10.tar.bz2 && \
    tar xf patchelf-0.10.tar.bz2 && \
    cd patchelf-0.10 && \
    ./configure && \
    make install
    

ENV PATH=/home/CMake-3.16.9/bin:$PATH
ENV PYTHON_LIBRARY="/usr/local/lib/python3.8"
ENV PYTHON_INCLUDE_DIRS="/usr/local/include/python3.8"

RUN python3.8 -m pip install pip==${PIP_VERSION} && \
  pip install --no-cache numpy wheel protobuf

RUN cd /; git clone https://github.com/Unstructured-IO/Unstructured.Paddle.git&& \
    cd Unstructured.Paddle && \ 
    git checkout utic/release/2.4 && \
    mkdir build && cd build && \
    PYTHON_EXECUTABLE=/usr/local/bin/python3.8 cmake .. -DPY_VERSION=3.8 -DPYTHON_INCLUDE_DIR=${PYTHON_INCLUDE_DIRS} \
        -DPYTHON_LIBRARY=${PYTHON_LIBRARY} -DWITH_GPU=OFF \
        -DWITH_AVX=OFF -DWITH_ARM=ON
RUN cd /Unstructured.Paddle/build; make -j$(nproc)
# RUN auditwheel repair /Unstructured.Paddle/build/python/dist/paddlepaddle-2.4.2-cp38-cp38-linux_aarch64.whl -w /wheelhouse
# still need to copy the wheel to the host machine and push to pypi