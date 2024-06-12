#!/bin/bash
BUILD=release

nim c -f -d:$BUILD -o:build/mac/nlcc src/cmd/nlcc.nim
cp build/mac/nlcc $HOME/bin

nim c -d:mingw --cpu:amd64 -f -d:$BUILD -o:build/win/nlcc.exe src/cmd/nlcc.nim

cp -r tmpl build/
cp -r dlls build/

docker save lcpython3.11:latest | gzip > build/lcpython3.11_latest.tar.gz