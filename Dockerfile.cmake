FROM base 
ARG CMAKE_URL
ARG CMAKE_URL_CHECKSUM

RUN aria2c --checksum="${CMAKE_URL_CHECKSUM}" -d /tmp -o cmake-install.x "${CMAKE_URL}" \
 && chmod +x /tmp/cmake-install.x \
 && mkdir -p /opt/cmake \
 && /tmp/cmake-install.x --skip-license --prefix=/opt/cmake \
 && rm -rf /tmp/*
