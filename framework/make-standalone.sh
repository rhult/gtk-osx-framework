#!/bin/bash

#
# make-standalone.sh  --  Make a given application bundle (created with
#                         XCode) stand-alone by including a converted
#                         copy of the framework.
#
# Copyright (C) 2008  Imendio AB
#

print_help()
{
	echo "Usage: `basename $0` <path-to-app-bundle>"
	exit 1
}

#
# Verify app bundle argument
#
if [ "x$*" = x ]; then
	print_help
	exit 1
fi

bundle="$*"

if [ ! -d $bundle ]; then
	echo "The directory $* does not exist"
	exit 1
fi

if [ ! -x $bundle ]; then
	echo "The application bundle in $* is not accessible"
	exit 1
fi

if [ ! -d "$bundle/Contents" -o ! -d "$bundle/Contents/MacOS" ]; then
	echo "$bundle does not seem to be a valid application bundle"
	exit 1
fi

# Save path to framework conversion script.
tmp=`pwd`/`dirname $0`/convert-to-app-bundle.sh

#
# Add framework
#

echo "Converting $bundle to stand-alone application bundle ..."

pushd . > /dev/null
cd $bundle/Contents

if [ ! -d Frameworks ]; then
	mkdir Frameworks
fi
cd Frameworks

sh $tmp
if [ $? -ne 0 ]; then
	popd > /dev/null
	echo "Conversion failed."
	exit 1
fi

cd ../MacOS

appname=`basename $bundle`
appname=`echo $appname | sed -e "s@\.app@@"`

echo -e "\nUpdating binary ..."

install_name_tool -change /Library/Frameworks/Gtk.framework/Gtk "@executable_path/../Frameworks/Gtk.framework/Gtk" $appname

popd > /dev/null

echo "Finished."

exit 0;
