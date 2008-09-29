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

# Unmount any left-over from previous attempts.
unmount()
{
    if [ "x$1" == x ]; then
        return
    fi

    dev=`hdiutil info | grep "$1" | awk '{print $1}'`
    if [ x$dev != x ]; then
        hdiutil detach $dev -quiet -force || echo "Failed unmouting."
    fi
}

do_abort()
{
    unmount "crdmg"
    exit 1
}

for pmdoc in `ls -d ../installer/*/installer.pmdoc`; do
    dirname=`dirname $pmdoc`
    package_name=`head -1 $dirname/package-name`
    package_version=`head -1 $dirname/package-version`
    package_filename="$package_name.mpkg"
    #image_filename="$package_name-$package_version.dmg"
    image_filename="`head -1 $dirname/image-filename`-$package_version.dmg"

    echo "Creating installer for $package_name..."
    /Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc $pmdoc -o "$package_filename"

    echo "Creating disk mage..."
    if [ -f $dirname/template.dmg.sparseimage ]; then
        echo "Using template..."

        # Copy the template and resize the copy so the contents will fit.
        cp $dirname/template.dmg.sparseimage "$image_filename".sparseimage

        # Get the needed size with some margin.
        size=`du -sk "$package_filename" | cut -f1`
        size=`expr $size + 2048`

        # Unmount any previous failed attempts.
        unmount crdmg

        echo "Resizing to ${size}k..."
        hdiutil resize -size ${size}k -quiet "$image_filename".sparseimage || exit 1

        mount=`mktemp -d -t crdmg`

        # Try to exit cleanly...
        trap do_abort SIGHUP SIGINT SIGTERM SIGQUIT SIGILL SIGTRAP SIGABRT SIGBUS

        # Mount the image.
        mkdir -p $mount
        hdiutil attach "$image_filename".sparseimage -private -noautoopen -quiet -mountpoint $mount || exit 1

        # Copy the contents, but first remove the placeholder.
        rm -f $mount/"$package_filename"

        echo "Copy installer to image..."
        tar cf - "$package_filename" | (cd "$mount" ; tar xfBp -)

        # Unmount.
        unmount crdmg

        # Convert to normal readonly image.
        echo "Convert to final image..."
        rm -f "$image_filename"
        hdiutil convert "$image_filename".sparseimage -format UDRO -quiet -o "$image_filename"
        rm "$image_filename".sparseimage
    else
        echo "Not using template."
        hdiutil create -format UDRO -quiet -srcfolder "$package_filename" -volname "$package_name" "$image_filename" || exit $?
    fi
done


# Create template:
# hdiutil create -size 512k -layout NONE -fs 'HFS+' -type "SPARSE" -volname "Name here..." template.dmg
# Open it, drag in background.png, set size, background, icon size, text size.
# Unmount.
