# Image name used while tagging the final stage.
variable "IMAGE" { 
  default = "final" 
}

# Image version used while tagging the final stage.
variable "VERSION" { 
  default = "latest" 
}

variable "ENV_OS" {
  default = [
    "debian",
    "rhel",
  ]
}

variable "ENV_TARGETS" {
  default = [
    "rhel-gcc11",
    "rhel-gcc14",
    "debian-clang20",
    "rhel-dpcpp2025_3"
  ]
}

group "default" {
  targets = concat([for env in ENV_TARGETS : "final-${env}"], ["docs"])
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
  result = regex("[0-9]+[_0-9]*$", split("-", env)[1])
}

# pretty(debian-gcc11) → debian-gcc11
# pretty(rhel-dpcpp2025_3_2) → rhel-dpcpp2025.3.2
function "pretty" {
  params = [env]
  result = replace(env, "_", ".")
}

# ==========================================
# Targets/intermediate stages
# ==========================================

target "base" {
  matrix     = { env = ENV_OS }
  platforms  = ["linux/amd64"]
  name       = "base-${os(env)}"
  dockerfile = "Dockerfile.base"
  target     = os(env)
}

target "cc" {
  matrix     = { env = ENV_TARGETS }
  platforms  = ["linux/amd64"]
  name       = "cc-${env}"
  dockerfile = "Dockerfile.cc.${cc(env)}"
  # RHEL ships gcc11 as the system's default compiler and not as a toolset:
  target     = env == "rhel-gcc11" ? "rhel-gcc11" : os(env)
  contexts = {
    base = "target:base-${os(env)}"
  }
  args = {
    CC_VERSION = pretty(ccver(env))
  }
}

# ==========================================
# Source stages
# ==========================================

target "boost" {
  matrix     = { env = ENV_TARGETS }
  platforms  = ["linux/amd64"]
  name       = "boost-${env}"
  dockerfile = "Dockerfile.boost"
  contexts = {
    base = "target:cc-${env}"
  }
  args = {
    BOOST_BUILD_TOOLSET = cc(env)
  }
}

# ==========================================
# Final targets
# ==========================================

target "final" {
  matrix     = { env = ENV_TARGETS }
  platforms  = ["linux/amd64"]
  name       = "final-${env}"
  dockerfile = "Dockerfile.final"
  target     = os(env)
  contexts = {
    base  = "target:cc-${env}",
    boost = "target:boost-${env}"
  }
  args = {
    # If cc is dpcpp, it's mandatory to use the same version for mkl, 
    # otherwise the usual setvars script would do a mess.
    # On the other hand, when cc != dpcpp we can pick whatever version we want.
    ONEAPI_VERSION = cc(env) == "dpcpp" ? pretty(ccver(env)) : "2025.3"
  }
  tags = [
    "${IMAGE}:${pretty(env)}-${VERSION}",
    "${IMAGE}:${pretty(env)}-latest"
  ]
}

target "docs" {
  platforms  = ["linux/amd64"]
  dockerfile = "Dockerfile.docs"
  tags = [
    "${IMAGE}:docs-${VERSION}",
    "${IMAGE}:docs-latest"
  ]
}
