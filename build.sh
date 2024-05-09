#!/bin/bash
BUILD=debug

nim c -f -d:$BUILD -o:bin/nlcc src/cmd/nlcc.nim
cp bin/nlcc $HOME/bin
