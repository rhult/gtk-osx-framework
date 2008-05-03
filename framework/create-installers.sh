#!/bin/bash
#
# Prepares frameworks for system installation and creates installers.
#
# Copyright (C) 2007, 2008 Imendio AB
#

for framework in `ls -d *.framework`; do
    echo "Preparing $framework..."
    ./prepare-for-system.sh $framework
done

for pmdoc in `ls -d ../installer/*/installer-*.pmdoc`; do
    dirname=`dirname $pmdoc`
    package_name=`head -1 $dirname/package-name`

    echo "Creating installer for $package_name..."
    /Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc $pmdoc -o "$package_name.mpkg"
done
