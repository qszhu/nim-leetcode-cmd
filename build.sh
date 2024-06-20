#!/bin/bash
BUILD=release
# BUILD=debug

nim c -f -d:$BUILD -o:build/mac/nlcc src/cmd/nlcc.nim
cp build/mac/nlcc $HOME/bin

nim c -f -d:$BUILD -o:build/mac/nlc src/cmd/nlc.nim
cp build/mac/nlc $HOME/bin

if [ "$BUILD" = "release" ]; then
  PATH=.:$PATH nim c \
    -f \
    -d:$BUILD \
    --os:windows \
    --cpu:amd64 \
    --cc:clang \
    --clang.exe="zigcc" \
    --clang.linkerexe="zigcc" \
    --passC:"-target x86_64-windows" \
    --passL:"-target x86_64-windows" \
    -o:build/win/nlcc.exe \
    src/cmd/nlcc.nim

  cp -r tmpl build/
  cp -r dlls build/

  cd docker/python3 && ./build.sh && cd -
  cd docker/javascript && ./build.sh && cd -
fi
