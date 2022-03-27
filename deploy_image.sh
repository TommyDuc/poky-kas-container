#!/bin/sh

DISTRO_CROPS_POKY=${1:-ubuntu-18.04}
KAS_VERSION=${2:-2.6.2}

./build_image.sh $1 $2

docker push dimonoff/poky-kas-container:${DISTRO_CROPS_POKY}-kas-${KAS_VERSION}
