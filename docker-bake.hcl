variable "GCC_VERSION" { default = "14" }
variable "CLANG_VERSION" { default = "20" }

variable "CMAKE_URL" { 
  default = "https://github.com/Kitware/CMake/releases/download/v3.31.6/cmake-3.31.6-Linux-x86_64.sh"
}
variable "CMAKE_URL_CHECKSUM_SHA256" { 
  default = "518c76bd18cc4ca5faab891db69b1289dc1bf134f394f0983a19576711b95210" 
}

variable "BOOST_URL" { 
  default = "https://archives.boost.io/release/1.87.0/source/boost_1_87_0.tar.gz" 
}
variable "BOOST_URL_CHECKSUM_SHA256" { 
  default = "f55c340aa49763b1925ccf02b2e83f35fdcf634c9d5164a2acb87540173c741d"
}

variable "MKL_URL" {
  default="https://registrationcenter-download.intel.com/akdlm/IRC_NAS/db60f483-f02e-4f7e-9bcd-5e01dba97444/intel-onemkl-2026.0.0.909_offline.sh"
}
variable "MKL_URL_CHECKSUM_SHA256" {
  default = "f63fd6ce3a374993caa0482fec0a3b9f2c312beeabff82009ab51fca90c97225"
}

# Default group builds both matrix pipelines simultaneously
group "default" {
  targets = ["final"]
}

# Generates: base-ubuntu and base-rhel
target "base" {
  matrix = {
    os = ["ubuntu", "rhel"]
  }
  name       = "base-${os}"
  dockerfile = "Dockerfile.base"
  target     = os
  platforms = ["linux/amd64"]
  args = {
    GCC_VERSION = GCC_VERSION
  }
}

target "mkl" {
  matrix = { os = ["ubuntu", "rhel"] }
  name   = "mkl-${os}"
  dockerfile = "Dockerfile.mkl" 
  contexts = {
    base = "target:base-${os}"
  }
  args = {
    MKL_URL = MKL_URL
    MKL_URL_CHECKSUM_SHA256 = MKL_URL_CHECKSUM_SHA256
  }
}

# Generates: cmake-ubuntu and cmake-rhel
target "cmake" {
  matrix = {
    os = ["ubuntu", "rhel"]
  }
  name       = "cmake-${os}"
  dockerfile = "Dockerfile.cmake"
  contexts = {
    base = "target:base-${os}"
  }
  args = {
    CMAKE_URL = CMAKE_URL
    CMAKE_URL_CHECKSUM_SHA256 = CMAKE_URL_CHECKSUM_SHA256
  }
}

# Generates: boost-ubuntu and boost-rhel
target "boost" {
  matrix = {
    os = ["ubuntu", "rhel"]
  }
  name       = "boost-${os}"
  dockerfile = "Dockerfile.boost"
  contexts = {
    base = "target:base-${os}"
  }
  args = {
    BOOST_URL = BOOST_URL
    BOOST_URL_CHECKSUM_SHA256 = BOOST_URL_CHECKSUM_SHA256
  }
}

# Generates: final-ubuntu and final-rhel
target "final" {
  matrix = {
    os = ["ubuntu", "rhel"]
  }
  name       = "final-${os}"
  dockerfile = "Dockerfile.final"
  contexts = {
    base          = "target:base-${os}"
    cmake-builder = "target:cmake-${os}"
    boost-builder = "target:boost-${os}"
    mkl-builder   = "target:mkl-${os}"
  }
  tags = [
    "my-cpp-builder:${os}-latest"
  ]
}
