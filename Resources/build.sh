#!/bin/sh
set -e
mkdir -p tmp
cd tmp
unzip ../uif2iso.zip
export CFLAGS="-O2 -force_cpusubtype_ALL -mmacosx-version-min=10.4 -arch i386 -arch ppc"
make -C src
mv src/uif2iso ..
cd ..
rm -rf tmp