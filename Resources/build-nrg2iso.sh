#!/bin/sh
set -e

export CFLAGS="-O2 -force_cpusubtype_ALL -mmacosx-version-min=10.5 -arch i386 -arch ppc -arch x86_64"

mkdir -p tmp
cd tmp
tar xzvf ../nrg2iso-*.tar.gz --strip-components 1 
make
mv nrg2iso ..
cd ..
rm -rf tmp