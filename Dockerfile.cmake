# ==========================================
# Downloader stage
# Keep builder and downloader separated so
# different builders can reuse the same
# downloaded artifact.
# ==========================================
FROM base AS cmake-downloader

ARG CMAKE_URL
ARG CMAKE_URL_CHECKSUM_SHA256

RUN wget -O /tmp/cmake-install.x -q "${CMAKE_URL}" \
 && echo "${CMAKE_URL_CHECKSUM_SHA256} /tmp/cmake-install.x" | sha256sum --check - \
 && chmod +x /tmp/cmake-install.x

# ==========================================
# Builder stage
# ==========================================
FROM base

COPY --from=cmake-downloader /tmp/cmake-install.x /tmp/cmake-install.x

RUN mkdir -p /opt/cmake \
 && /tmp/cmake-install.x --prefix=/opt/cmake --skip-license \
 && rm -rf /tmp/*
