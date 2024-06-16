#!/bin/bash
BUILD=release
# BUILD=debug

nim c -f -d:$BUILD -o:build/mac/nlcc src/cmd/nlcc.nim
cp build/mac/nlcc $HOME/bin

nim c -d:mingw --cpu:amd64 -f -d:$BUILD -o:build/win/nlcc.exe src/cmd/nlcc.nim

if [ "$BUILD" = "release" ]; then
  cp -r tmpl build/
  cp -r dlls build/

  cd docker/python3 && ./build.sh && cd -
  cd docker/javascript && ./build.sh && cd -
fi
