#!/usr/bin/env bash

set -euo pipefail

PACKAGE_NAME=envoy
PACKAGE_ORG=envoyproxy
SCRIPT_PACKAGE_VERSION=v1.36.5
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}
PACKAGE_VERSION_WO_V="${PACKAGE_VERSION#v}"

# Patch hosted in IBM's ppc64le build-scripts repo
PATCH_URL="https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/e/envoy/envoy_${PACKAGE_VERSION}.patch"

wdir="$(pwd)"
echo "=== envoy-build.sh starting in ${wdir} for ${PACKAGE_NAME} ${PACKAGE_VERSION} ==="

# =============================================================================
# STAGE 1 — Base dependencies (UBI 9)
# =============================================================================
# EPEL
dnf install -y --nodocs --setopt=install_weak_deps=0 \
   https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Full CentOS Stream 9 repo set (BaseOS + AppStream + CRB) — keeps
# libstdc++ / libstdc++-devel / libstdc++-static version-aligned.
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official || true

dnf install -y --nodocs --setopt=install_weak_deps=0 \
    cmake \
    libatomic \
    libstdc++ \
    libstdc++-static \
    libstdc++-devel \
    libtool \
    lld \
    patch \
    python3-pip \
    openssl-devel \
    libffi-devel \
    unzip \
    wget \
    zip \
    java-21-openjdk-devel \
    git \
    gcc-c++ \
    xz \
    file \
    binutils \
    procps-ng \
    diffutils \
    ninja-build \
    aspell \
    aspell-en \
    sudo \
    python3.12 \
    python3.12-devel \
    python3.12-pip \
    curl-minimal \
    tar \
    which

# Environment for the rest of the build
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-21-openjdk-*' | head -n1)
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

# =============================================================================
# STAGE 2 — Envoy source + ppc64le patch
# =============================================================================
cd "${wdir}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

echo "=== Fetching ppc64le patch: ${PATCH_URL} ==="
curl -fsSL -o "../envoy_${PACKAGE_VERSION_WO_V}.patch" "${PATCH_URL}"
git apply "../envoy_${PACKAGE_VERSION_WO_V}.patch"

BAZEL_VERSION=$(cat .bazelversion)
cd "${wdir}"

# =============================================================================
# STAGE 3 — Bazel (built from source for ppc64le)
# =============================================================================
if [ ! -x "${wdir}/bazel/output/bazel" ]; then
    mkdir -p bazel
    cd bazel
    wget -q "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip"
    unzip -q "bazel-${BAZEL_VERSION}-dist.zip"
    rm -f "bazel-${BAZEL_VERSION}-dist.zip"
    export BAZEL_DEV_VERSION_OVERRIDE=${BAZEL_VERSION}
    env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
    cd "${wdir}"
fi
export PATH="${PATH}:${wdir}/bazel/output"

# =============================================================================
# STAGE 4 — Clang/LLVM 18 prebuilt for ppc64le
# =============================================================================
LLVM_TARBALL=clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8.tar.xz
LLVM_DIR=${wdir}/clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8
if [ ! -d "${LLVM_DIR}" ]; then
    wget -q "https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/${LLVM_TARBALL}"
    tar -xf "${LLVM_TARBALL}"
    rm -f "${LLVM_TARBALL}"
fi
export LLVM_DIR
export PATH=${LLVM_DIR}/bin:${PATH}
export CC=${LLVM_DIR}/bin/clang
export CXX=${LLVM_DIR}/bin/clang++
export LLVM_CONFIG=${LLVM_DIR}/bin/llvm-config
export LIBCLANG_PATH=${LLVM_DIR}/lib

# =============================================================================
# STAGE 5 — Rust + cross + cargo-bazel (for rules_rust 0.56.0)
# =============================================================================
if ! command -v cargo >/dev/null 2>&1; then
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
# shellcheck disable=SC1090
source "${HOME}/.cargo/env"
cargo install cross --version 0.2.1 --locked

cd "${wdir}"
if [ ! -x "${wdir}/rules_rust/crate_universe/target/powerpc64le-unknown-linux-gnu/release/cargo-bazel" ]; then
    git clone https://github.com/bazelbuild/rules_rust
    cd rules_rust
    git checkout 0.56.0
    cd crate_universe
    cross build --release --locked --bin cargo-bazel --target=powerpc64le-unknown-linux-gnu
    cd "${wdir}"
fi
export CARGO_BAZEL_GENERATOR_URL="file://${wdir}/rules_rust/crate_universe/target/powerpc64le-unknown-linux-gnu/releaszel"
export CARGO_BAZEL_REPIN=true

# =============================================================================
# STAGE 6 — Build Envoy
# =============================================================================
cd "${wdir}/${PACKAGE_NAME}"
bazel/setup_clang.sh "${LLVM_DIR}/"

bazel build //source/exe:envoy \
    -c opt \
    --config=clang-gnu \
    --define=wasm=disabled \
    --jobs=8 \
    --local_ram_resources=24000

# Sanity-check the produced binary
file bazel-bin/source/exe/envoy-static

# =============================================================================
# STAGE 7 — Post-build cleanup to shrink the committed builder layer
# =============================================================================
mkdir -p /out
cp "${wdir}/${PACKAGE_NAME}/bazel-bin/source/exe/envoy-static" /out/envoy
strip /out/envoy

# Scrub the heaviest build artefacts
rm -rf "${wdir}/bazel"  # bazel source + output
rm -rf "${wdir}/${PACKAGE_NAME}" # envoy source + bazel cache
rm -rf "${wdir}/rules_rust" # rust target dir
rm -rf "${wdir}/clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8"
rm -rf "${HOME}/.cargo" "${HOME}/.rustup"
rm -rf /root/.cache /tmp/* /var/cache/dnf
dnf clean all || true

echo "=== builder cleanup complete; /out/envoy is $(stat -c %s /out/envoy) bytes ==="

echo "=== envoy-build.sh completed successfully ==="
