#!/bin/bash
set -e
cd docker/python3 && ./build.sh && cd -
cd docker/javascript && ./build.sh && cd -
