#!/bin/bash
BUILD=release

nim c -f -d:$BUILD -o:build/mac/nlcc src/cmd/nlcc.nim
cp -r precompiled build/mac/
cp -r tmpl build/mac/
cp build/mac/nlcc $HOME/bin

nim c -d:mingw --cpu:amd64 -f -d:$BUILD -o:build/win/nlcc.exe src/cmd/nlcc.nim
cp -r precompiled build/win/
cp -r tmpl build/win/
cp dlls/* build/win/
