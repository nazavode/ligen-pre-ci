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
  matrix     = { env = ENV_TARGETS }
  platforms  = ["linux/amd64"]
  name       = "base-${env}"
  dockerfile = "Dockerfile.base.${cc(env)}"
  target     = os(env)
  args = {
    CC_VERSION     = pretty(ccver(env))
    # When cc != dpcpp, we need a oneAPI version to install MKL from.
    # Note: this is ignored when cc == dpcpp
    ONEAPI_VERSION = "2025.3"
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
  tags = [
    "${IMAGE}:${pretty(env)}-${VERSION}"
  ]
}

# ==========================================
# Docs target
# ==========================================

target "docs" {
  platforms  = ["linux/amd64"]
  dockerfile = "Dockerfile.docs"
  tags = [
    "${IMAGE}:docs-${VERSION}"
  ]
}
