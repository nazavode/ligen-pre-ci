# Image name used while tagging the final stage.
variable "IMAGE" { 
  default = "final" 
}

# Image version used while tagging the final stage.
variable "VERSION" { 
  default = "latest" 
}

variable "ENV_TARGETS" {
  default = [
    "debian-gcc11",
    "debian-gcc14",
    "rhel-gcc14",
    "debian-clang20"
  ]
}

group "default" {
  targets = [for env in ENV_TARGETS : "final-${env}"]
}

# ==========================================
# Helper functions to parse target environment
# strings
# ==========================================

# os(debian-gcc11) → debian
function "os" {
  params = [env]
  result = split("-", env)[0]
}

# cc(debian-gcc11) → gcc
function "cc" {
  params = [env]
  result = regex("^[a-z]+", split("-", env)[1])
}

# ccver(debian-gcc11) → 11
function "ccver" {
  params = [env]
  result = regex("[0-9]+$",  split("-", env)[1])
}

# ==========================================
# Targets/intermediate stages
# ==========================================

target "base" {
  matrix     = { env = ENV_TARGETS }
  platforms  = ["linux/amd64"]
  name       = "base-${env}"
  dockerfile = "Dockerfile.base.${cc(env)}"
  target     = os(env)
  args = {
    CC_VERSION   = ccver(env)
  }
}

target "boost" {
  matrix     = { env = ENV_TARGETS }
  platforms  = ["linux/amd64"]
  name       = "boost-${env}"
  dockerfile = "Dockerfile.boost"
  contexts = {
    base = "target:base-${env}"
  }
  args = {
    BOOST_BUILD_TOOLSET       = cc(env)
    BOOST_URL                 = "https://archives.boost.io/release/1.87.0/source/boost_1_87_0.tar.gz" 
    BOOST_URL_CHECKSUM_SHA256 = "f55c340aa49763b1925ccf02b2e83f35fdcf634c9d5164a2acb87540173c741d"
  }
}

# ==========================================
# Final target
# ==========================================

target "final" {
  matrix     = { env = ENV_TARGETS }
  platforms  = ["linux/amd64"]
  name       = "final-${env}"
  dockerfile = "Dockerfile.final"
  contexts = {
    base          = "target:base-${env}"
    boost-builder = "target:boost-${env}"
  }
  args = {
    CMAKE_URL                 = "https://github.com/Kitware/CMake/releases/download/v3.31.6/cmake-3.31.6-Linux-x86_64.sh"
    CMAKE_URL_CHECKSUM_SHA256 = "518c76bd18cc4ca5faab891db69b1289dc1bf134f394f0983a19576711b95210" 
    MKL_URL                   = "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/db60f483-f02e-4f7e-9bcd-5e01dba97444/intel-onemkl-2026.0.0.909_offline.sh"
    MKL_URL_CHECKSUM_SHA256   = "f63fd6ce3a374993caa0482fec0a3b9f2c312beeabff82009ab51fca90c97225"
  }
  tags = [
    "${IMAGE}:${env}-${VERSION}"
  ]
}
