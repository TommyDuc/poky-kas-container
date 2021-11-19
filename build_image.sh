#!/bin/sh

DISTRO_CROPS_POKY=${1:-ubuntu-18.04}
KAS_VERSION=${2:-2.6.2}

docker build --build-arg BASE_DISTRO=${BASE_DISTRO} --build-arg KAS_VERSION=${KAS_VERSION} -t dimonoff/crops/poky/kas:${DISTRO_CROPS_POKY}-kas-${KAS_VERSION} .
