#!/bin/bash
#
# Prepares frameworks for system installation and installs them.
#
# Copyright (C) 2007, 2008 Imendio AB
#

for framework in `ls -d *.framework`; do
    basename=`basename "$framework"`

    echo "Installing $basename..."

    ./prepare-for-system.sh $framework

    rm -r /Library/Frameworks/$basename 2>/dev/null
    cp -r $framework /Library/Frameworks
done
