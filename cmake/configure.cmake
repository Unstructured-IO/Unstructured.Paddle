# Copyright (c) 2016 PaddlePaddle Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if(NOT WITH_PYTHON)
  add_definitions(-DPADDLE_NO_PYTHON)
endif()

if(WITH_TESTING)
  add_definitions(-DPADDLE_WITH_TESTING)
endif()

if(WITH_INFERENCE_API_TEST)
  add_definitions(-DPADDLE_WITH_INFERENCE_API_TEST)
endif()

if(NOT WITH_PROFILER)
  add_definitions(-DPADDLE_DISABLE_PROFILER)
endif()

if(WITH_AVX AND AVX_FOUND)
  set(SIMD_FLAG ${AVX_FLAG})
  add_definitions(-DPADDLE_WITH_AVX)
elseif(SSE3_FOUND AND NOT WIN32)
  set(SIMD_FLAG ${SSE3_FLAG})
endif()

if(SSE3_FOUND)
  # TODO: Runtime detection should be used here.
  add_definitions(-DPADDLE_WITH_SSE3)
endif()

if(WIN32)
  # windows header option for all targets.
  add_definitions(-D_XKEYCHECK_H)
  # Use symbols instead of absolute path, reduce the cmake link command length.
  set(CMAKE_C_USE_RESPONSE_FILE_FOR_LIBRARIES 1)
  set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_LIBRARIES 1)
  set(CMAKE_C_USE_RESPONSE_FILE_FOR_OBJECTS 1)
  set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_OBJECTS 1)
  set(CMAKE_C_USE_RESPONSE_FILE_FOR_INCLUDES 1)
  set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_INCLUDES 1)
  set(CMAKE_C_RESPONSE_FILE_LINK_FLAG "@")
  set(CMAKE_CXX_RESPONSE_FILE_LINK_FLAG "@")

  add_definitions(-DPADDLE_DLL_INFERENCE)
  # set definition for the dll export
  if(NOT MSVC)
    message(
      FATAL
      "Windows build only support msvc. Which was binded by the nvcc compiler of NVIDIA."
    )
  endif()
endif()

if(WITH_MUSL)
  add_definitions(-DPADDLE_WITH_MUSL)

  message(STATUS, "Set compile option WITH_MKL=OFF when WITH_MUSL=ON")
  set(WITH_MKL OFF)

  message(STATUS, "Set compile option WITH_GPU=OFF when WITH_MUSL=ON")
  set(WITH_GPU OFF)
endif()

if(WITH_PSLIB)
  add_definitions(-DPADDLE_WITH_PSLIB)
endif()

if(WITH_ARM_BRPC)
  add_definitions(-DPADDLE_WITH_ARM_BRPC)
endif()

if(WITH_FLPS)
  add_definitions(-DPADDLE_WITH_FLPS)
endif()

if(WITH_GLOO)
  add_definitions(-DPADDLE_WITH_GLOO)
endif()

if(WITH_BOX_PS)
  add_definitions(-DPADDLE_WITH_BOX_PS)
endif()

if(WITH_XPU)
  message(STATUS "Compile with XPU!")
  add_definitions(-DPADDLE_WITH_XPU)
endif()

if(WITH_XPU_KP)
  message(STATUS "Compile with XPU_KP!")
  add_definitions(-DPADDLE_WITH_XPU_KP)
endif()

if(WITH_IPU)
  message(STATUS "Compile with IPU!")
  add_definitions(-DPADDLE_WITH_IPU)
endif()

if(WITH_GPU)
  add_definitions(-DPADDLE_WITH_CUDA)
  add_definitions(-DEIGEN_USE_GPU)

  find_package(CUDA REQUIRED)

  if(${CMAKE_CUDA_COMPILER_VERSION} VERSION_LESS 10.1)
    message(FATAL_ERROR "Paddle needs CUDA >= 10.1 to compile")
  endif()

  if(NOT CUDNN_FOUND)
    message(FATAL_ERROR "Paddle needs cudnn to compile")
  endif()

  if(${CUDNN_MAJOR_VERSION} VERSION_LESS 7)
    message(FATAL_ERROR "Paddle needs CUDNN >= 7.0 to compile")
  endif()

  if(CUPTI_FOUND)
    include_directories(${CUPTI_INCLUDE_DIR})
    add_definitions(-DPADDLE_WITH_CUPTI)
  else()
    message(STATUS "Cannot find CUPTI, GPU Profiling is incorrect.")
  endif()
  set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcompiler=\"${SIMD_FLAG}\"")

  # Include cuda and cudnn
  include_directories(${CUDNN_INCLUDE_DIR})
  include_directories(${CUDA_TOOLKIT_INCLUDE})

  if(TENSORRT_FOUND)
    if(WIN32)
      if(${CMAKE_CUDA_COMPILER_VERSION} VERSION_LESS 9)
        message(FATAL_ERROR "TensorRT needs CUDA >= 9.0 to compile on Windows")
      endif()
    else()
      if(${CMAKE_CUDA_COMPILER_VERSION} VERSION_LESS 8)
        message(FATAL_ERROR "TensorRT needs CUDA >= 8.0 to compile")
      endif()
      if(${CUDNN_MAJOR_VERSION} VERSION_LESS 7)
        message(FATAL_ERROR "TensorRT needs CUDNN >= 7.0 to compile")
      endif()
      if(${TENSORRT_MAJOR_VERSION} VERSION_LESS 4)
        message(FATAL_ERROR "Paddle needs TensorRT >= 4.0 to compile")
      endif()
    endif()
    include_directories(${TENSORRT_INCLUDE_DIR})
  endif()
elseif(WITH_ROCM)
  add_definitions(-DPADDLE_WITH_HIP)
  add_definitions(-DEIGEN_USE_GPU)
  add_definitions(-DEIGEN_USE_HIP)

  if(CUPTI_FOUND)
    include_directories(${CUPTI_INCLUDE_DIR})
    add_definitions(-DPADDLE_WITH_CUPTI)
  else()
    message(STATUS "Cannot find CUPTI, GPU Profiling is incorrect.")
  endif()

  if(NOT MIOPEN_FOUND)
    message(FATAL_ERROR "Paddle needs MIOpen to compile")
  endif()

  if(${MIOPEN_VERSION} VERSION_LESS 2090)
    message(FATAL_ERROR "Paddle needs MIOPEN >= 2.9 to compile")
  endif()
else()
  add_definitions(-DHPPL_STUB_FUNC)
  list(APPEND CMAKE_CXX_SOURCE_FILE_EXTENSIONS cu)
endif()

if(WITH_MKLML AND MKLML_IOMP_LIB)
  message(STATUS "Enable Intel OpenMP with ${MKLML_IOMP_LIB}")
  if(WIN32)
    # openmp not support well for now on windows
    set(OPENMP_FLAGS "")
  else()
    set(OPENMP_FLAGS "-fopenmp")
  endif()
  set(CMAKE_C_CREATE_SHARED_LIBRARY_FORBIDDEN_FLAGS ${OPENMP_FLAGS})
  set(CMAKE_CXX_CREATE_SHARED_LIBRARY_FORBIDDEN_FLAGS ${OPENMP_FLAGS})
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OPENMP_FLAGS}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OPENMP_FLAGS}")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SIMD_FLAG}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SIMD_FLAG}")

if(WITH_DISTRIBUTE)
  add_definitions(-DPADDLE_WITH_DISTRIBUTE)
endif()

if(WITH_PSCORE)
  add_definitions(-DPADDLE_WITH_PSCORE)
endif()

if(WITH_RPC)
  add_definitions(-DPADDLE_WITH_RPC)
endif()

if(WITH_HETERPS)
  add_definitions(-DPADDLE_WITH_HETERPS)
endif()

if(WITH_BRPC_RDMA)
  add_definitions(-DPADDLE_WITH_BRPC_RDMA)
endif()

if(ON_INFER)
  add_definitions(-DPADDLE_ON_INFERENCE)
endif()

if(WITH_CRYPTO)
  add_definitions(-DPADDLE_WITH_CRYPTO)
endif()

if(WITH_CUSTOM_DEVICE AND NOT WIN32)
  add_definitions(-DPADDLE_WITH_CUSTOM_DEVICE)
endif()
if(WITH_GPU_GRAPH)
  add_definitions(-DPADDLE_WITH_GPU_GRAPH)
endif()

if(WITH_CUDNN_FRONTEND)
  add_definitions(-DPADDLE_WITH_CUDNN_FRONTEND)
endif()
