# =============================================================================
# TeamSync Editor - Multi-Stage Dockerfile
# 
# MPL 2.0 Compliant
# =============================================================================

# =============================================================================
# STAGE 1: Builder Base - Install build dependencies
# =============================================================================
FROM ubuntu:22.04 AS builder-base

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies (cached layer)
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core build tools
    build-essential \
    git \
    automake \
    autoconf \
    libtool \
    pkg-config \
    # Required libraries
    libcap-dev \
    libcap2-bin \
    libpng-dev \
    libssl-dev \
    libpam-dev \
    libzstd-dev \
    libpoco-dev \
    libcppunit-dev \
    # Python for branding scripts
    python3 \
    python3-lxml \
    python3-polib \
    # Utilities
    wget \
    curl \
    ca-certificates \
    fontconfig \
    cpio \
    rsync \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18 LTS (required for browser build tools)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

# =============================================================================
# STAGE 2: LibreOffice Core - Download pre-built assets
# =============================================================================
FROM builder-base AS locore

ARG LO_CORE_VERSION=24.04

WORKDIR /build

# Download pre-built LibreOffice core assets (saves hours of build time)
RUN echo "Downloading LibreOffice core assets (co-${LO_CORE_VERSION})..." && \
    wget -q --show-progress \
    https://github.com/CollaboraOnline/online/releases/download/for-code-assets/core-co-${LO_CORE_VERSION}-assets.tar.gz \
    -O core-assets.tar.gz && \
    tar -xzf core-assets.tar.gz && \
    rm core-assets.tar.gz && \
    echo "LibreOffice core assets ready."

# =============================================================================
# STAGE 3: Build Collabora Online with White-Labeling
# =============================================================================
FROM locore AS builder

ARG COOL_VERSION=distro/collabora/co-24.04
ARG BRAND_NAME="TeamSync Editor"
ARG BRAND_SHORT="TeamSync"

WORKDIR /build

# Clone Collabora Online source
RUN echo "Cloning Collabora Online (${COOL_VERSION})..." && \
    git clone --depth 1 --branch ${COOL_VERSION} \
    https://github.com/CollaboraOnline/online.git && \
    echo "Source code ready."

# Copy branding assets
COPY docker/branding/ /build/branding/

# Copy and run white-label script
COPY docker/scripts/white-label.sh /build/white-label.sh
RUN chmod +x /build/white-label.sh && \
    echo "Applying TeamSync branding..." && \
    /build/white-label.sh /build/online /build/branding

# Replace logo files with TeamSync branding
RUN if [ -f /build/branding/images/logo.svg ]; then \
        find /build/online/browser -type f -name "collabora-logo*.svg" \
            -exec cp /build/branding/images/logo.svg {} \; 2>/dev/null || true; \
        find /build/online/browser -type f -name "loleaflet-logo*.svg" \
            -exec cp /build/branding/images/logo.svg {} \; 2>/dev/null || true; \
    fi

# Apply custom CSS
RUN if [ -f /build/branding/css/brand-colors.css ]; then \
        cat /build/branding/css/brand-colors.css >> \
            /build/online/browser/src/control/Control.UIManager.css 2>/dev/null || true; \
    fi

# Install browser dependencies
WORKDIR /build/online/browser
RUN npm install

# Configure and build coolwsd (this also builds browser assets)
WORKDIR /build/online

RUN ./autogen.sh

# Use /opt/lokit as LO path (matching official Collabora structure)
RUN ./configure \
    --prefix=/opt/cool \
    --with-lokit-path=/build/include \
    --with-lo-path=/opt/lokit \
    --enable-silent-rules \
    --disable-setcap \
    --disable-ssl

RUN make -j$(nproc)

# Install to /opt/cool
RUN make DESTDIR=/install install

# Copy LibreOffice to /opt/lokit (matching configure --with-lo-path)
RUN mkdir -p /opt/lokit && cp -r /build/instdir/* /opt/lokit/

# Remove unnecessary LibreOffice components (keep Writer + Calc only)
# IMPORTANT: Do NOT remove program/*.so files as they are part of the merged library
RUN cd /opt/lokit && \
    rm -rf help/ share/wizards/ share/gallery/ share/extensions/ \
           program/classes/ share/template/ share/samples/ 2>/dev/null || true && \
    echo "LibreOffice cleanup complete"

# Create systemplate - this sets up the jail template with symlinks to /opt/lokit
RUN echo "Etc/UTC" > /etc/timezone && \
    ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    mkdir -p /install/opt/cool/systemplate /install/opt/cool/child-roots && \
    ./coolwsd-systemplate-setup /install/opt/cool/systemplate /opt/lokit || true

# =============================================================================
# STAGE 4: Runtime Image (Minimal)
# =============================================================================
FROM ubuntu:22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

# Labels
LABEL maintainer="TeamSync Editor"
LABEL description="TeamSync Editor - Collaborative document editing"
LABEL org.opencontainers.image.licenses="MPL-2.0"
LABEL org.opencontainers.image.source="https://github.com/CollaboraOnline/online"

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcap2 \
    libcap2-bin \
    libpng16-16 \
    libssl3 \
    libpam0g \
    libzstd1 \
    # Poco libraries (runtime dependencies pulled automatically)
    libpoco-dev \
    ca-certificates \
    curl \
    procps \
    # Fonts for document rendering (optimized selection)
    fontconfig \
    # MS Office compatible fonts (Liberation = Arial/Times/Courier alternatives)
    fonts-liberation \
    fonts-crosextra-carlito \
    fonts-crosextra-caladea \
    # Indic/Devanagari fonts (Hindi support)
    fonts-lohit-deva \
    fonts-indic \
    # Arabic fonts
    fonts-noto-ui-core \
    # Additional open fonts
    fonts-roboto \
    # Spell checking
    hunspell \
    hunspell-en-us \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create cool user
RUN useradd -r -M -d /opt/cool -s /bin/false cool

# Create directories
RUN mkdir -p \
    /opt/cool/systemplate \
    /opt/cool/child-roots \
    /opt/cool/browser \
    /etc/coolwsd \
    /var/log/coolwsd \
    /var/cache/coolwsd \
    /tmp/coolwsd

# Copy all files from builder
COPY --from=builder /install/opt/cool/bin /opt/cool/bin
COPY --from=builder /install/opt/cool/share /opt/cool/share
COPY --from=builder /install/opt/cool/systemplate /opt/cool/systemplate
COPY --from=builder /install/opt/cool/child-roots /opt/cool/child-roots
COPY --from=builder /opt/lokit /opt/lokit
COPY --from=builder /build/online/coolwsd.xml /etc/coolwsd/coolwsd.xml

# Copy LICENSE notice for MPL compliance
COPY docker/branding/LICENSE_NOTICE.txt /opt/cool/LICENSE_NOTICE.txt

# Create symlinks, set permissions and capabilities in a single layer
RUN ln -sf /opt/cool/share/coolwsd/browser /opt/cool/bin/browser && \
    ln -sf /opt/cool/share/coolwsd/discovery.xml /opt/cool/bin/discovery.xml && \
    ln -sf /opt/cool/share/coolwsd/favicon.ico /opt/cool/bin/favicon.ico && \
    ln -sf /opt/cool/systemplate /opt/cool/bin/systemplate && \
    mkdir -p /opt/cool/bin/jails && \
    chown -R cool:cool /opt/cool /var/log/coolwsd /var/cache/coolwsd /tmp/coolwsd && \
    chmod 755 /opt/cool/bin/* && \
    (setcap cap_fowner,cap_chown,cap_mknod,cap_sys_chroot=ep /opt/cool/bin/coolforkit-caps 2>/dev/null || \
     setcap cap_fowner,cap_chown,cap_mknod,cap_sys_chroot=ep /opt/cool/bin/coolforkit-ns 2>/dev/null || true)

# Copy entrypoint script
COPY docker/scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port
EXPOSE 9980

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD curl -sf http://localhost:9980/hosting/discovery > /dev/null || exit 1

WORKDIR /opt/cool

ENTRYPOINT ["/entrypoint.sh"]
