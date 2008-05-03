#!/bin/bash
#
# Prepares frameworks for system installation and creates installers.
#
# Copyright (C) 2007, 2008 Imendio AB
#

for framework in `ls -d *.framework`; do
    basename=`basename "$framework"`

    pmdoc=../package/$framework/installer-$framework.pmdoc

    if [ -f $pmdoc ]; then
        echo "Preparing $basename..."
        ./prepare-for-system.sh $framework

        echo "Creating installer..."
        /Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc $pmdoc
    fi
done
