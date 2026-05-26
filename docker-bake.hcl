variable "GCC_VERSION" { default = "14" }
variable "CMAKE_VERSION" { default = "3.31.6" }
variable "BOOST_VERSION" { default = "1.87.0" }

variable "CMAKE_URL" { 
  default = "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh"
}
variable "CMAKE_URL_CHECKSUM" { 
  default = "sha-256=518c76bd18cc4ca5faab891db69b1289dc1bf134f394f0983a19576711b95210" 
}

variable "BOOST_URL" { 
  default = "https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${replace(BOOST_VERSION, ".", "_")}.tar.gz" 
}
variable "BOOST_URL_CHECKSUM" { 
  default = "sha-256=f55c340aa49763b1925ccf02b2e83f35fdcf634c9d5164a2acb87540173c741d"
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

# Generates: cmake-ubuntu and cmake-rhel
target "cmake" {
  matrix = {
    os = ["ubuntu", "rhel"]
  }
  name       = "cmake-${os}"
  dockerfile = "Dockerfile.cmake"
  contexts = {
    base = "target:base-${os}" # Dynamically links to the correct OS base
  }
  args = {
    CMAKE_URL = CMAKE_URL
    CMAKE_URL_CHECKSUM = CMAKE_URL_CHECKSUM
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
    base = "target:base-${os}" # Dynamically links to the correct OS base
  }
  args = {
    BOOST_URL = BOOST_URL
    BOOST_URL_CHECKSUM = BOOST_URL_CHECKSUM
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
  }
  tags = [
    "my-cpp-builder:${os}-latest"
  ]
}
