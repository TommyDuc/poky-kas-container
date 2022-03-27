#!/bin/sh

DISTRO_CROPS_POKY=${1:-ubuntu-18.04}
KAS_VERSION=${2:-2.6.2}

docker build --build-arg DISTRO_CROPS_POKY=${DISTRO_CROPS_POKY} --build-arg KAS_VERSION=${KAS_VERSION} -t dimonoff/poky-kas-container:${DISTRO_CROPS_POKY}-kas-${KAS_VERSION} .
