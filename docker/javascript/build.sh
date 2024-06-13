#!/bin/bash
docker build --platform linux/amd64 -t lcnodejs20.10.0 .
docker save lcnodejs20.10.0:latest | gzip > ../../build/lcnodejs20.10.0_amd64.tar.gz
docker build --platform linux/arm64 -t lcnodejs20.10.0 .
docker save lcnodejs20.10.0:latest | gzip > ../../build/lcnodejs20.10.0_arm64.tar.gz
