# Copyright (C) 2015-2016 Intel Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# Since this Dockerfile is used in multiple images, force the builder to
# specify the BASE_DISTRO. This should hopefully prevent accidentally using
# a default, when another distro was desired.

ARG DISTRO_CROPS_POKY

FROM "docker.io/crops/poky:${DISTRO_CROPS_POKY:?}"

LABEL org.opencontainers.image.authors="wbonetti@dimonoff.com"
LABEL maintainer="wbonetti@dimonoff.com"

USER root

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
    pylint3 python3-setuptools python3-wheel python3-yaml python3-distro python3-jsonschema python3-newt \
    awscli \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG KAS_VERSION

RUN pip3 install "kas==${KAS_VERSION:?}"

USER usersetup
ENV LANG=en_US.UTF-8
