#!/bin/bash
docker build --platform linux/amd64 -t lcpython3.11 .
docker save lcpython3.11:latest | gzip > ../../build/lcpython3.11_amd64.tar.gz
docker build --platform linux/arm64 -t lcpython3.11 .
docker save lcpython3.11:latest | gzip > ../../build/lcpython3.11_arm64.tar.gz
