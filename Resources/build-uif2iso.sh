#!/bin/sh
set -e

export CFLAGS="-O2 -force_cpusubtype_ALL -mmacosx-version-min=10.5 -arch i386 -arch ppc -arch x86_64"

mkdir -p tmp
cd tmp
unzip ../uif2iso.zip
make -C src
mv src/uif2iso ..
cd ..
rm -rf tmp