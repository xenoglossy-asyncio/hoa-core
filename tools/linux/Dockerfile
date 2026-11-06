# SPDX-License-Identifier: GPL-2.0-or-later
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        curl \
        ca-certificates \
        pkg-config \
        patchelf \
        rsync \
        libmariadb-dev \
        libmariadb-dev-compat \
        libssl-dev \
        zlib1g-dev \
        libasound2-dev \
        libudev-dev \
        libwayland-dev \
        libxkbcommon-dev \
        clang \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal

ENV PATH=/root/.cargo/bin:$PATH
