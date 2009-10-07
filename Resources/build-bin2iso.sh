#!/bin/sh
set -e

export CFLAGS="-O2 -force_cpusubtype_ALL -mmacosx-version-min=10.5 -arch i386 -arch ppc -arch x86_64"

gcc bin2iso*.c -o bin2iso