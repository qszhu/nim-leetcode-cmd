#!/bin/bash
BUILD=release

nim c -f -d:$BUILD -o:bin/nlcc src/cmd/nlcc.nim
cp bin/nlcc $HOME/bin

nim c -d:mingw --cpu:amd64 -f -d:$BUILD -o:bin/nlcc.exe src/cmd/nlcc.nim