#!/bin/bash
#
# Prepares frameworks for system installation and creates installers.
#
# Copyright (C) 2007, 2008 Imendio AB
#

for framework in `ls -d *.framework`; do
    basename=`basename "$framework"`

    framework_name=`echo $basename | sed -e 's@\(^.*\)\..*@\1@'`
    pmdoc=../installer/$framework_name/installer-$framework_name.pmdoc

    if [ -d $pmdoc ]; then
        echo "Preparing $basename..."
        ./prepare-for-system.sh $framework

        package_name=`head -1 ../installer/$framework_name/package-name`

        echo "Creating installer..."
        /Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc $pmdoc -o "$package_name.mpkg"
    fi
done
