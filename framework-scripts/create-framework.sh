#!/bin/bash

#
# create-framework.sh  --  Create an OS X Gtk.framework out of a
#                          GTK+ installed in a prefix.
#
# Copyright (C) 2007, 2008  Imendio AB
#

# Constants
starting_point="libgtk-quartz-2.0.0.dylib";

print_help()
{
	echo "Usage: `basename $0` <prefix>"
	exit 1
}

#
# Verify prefix
#
if [ "x$*" = x ]; then
	print_help
	exit 1
fi

prefix="$*"

if [ ! -d $prefix ]; then
	echo "The directory $* does not exist"
	exit 1
fi

if [ ! -x $prefix ]; then
	echo "The framework in $* is not accessible"
	exit 1
fi

# drop trailing slash
prefix=`dirname "$prefix"`/`basename "$prefix"`
prefix=`echo $prefix | sed -e "s@//@/@"`

libprefix="$prefix/lib"
top_level="$prefix/lib/$starting_point"

if [ ! -x "$top_level" ]; then
	echo "$prefix/lib/$starting_point does not exist.";
	exit 1;
fi

framework="`pwd`/Gtk.framework";
new_prefix="$framework/Libraries";

#
# 1. Create Gtk.framework directory.
#
echo "Creating framework in ./Gtk.framework ..."

if [ -x Gtk.framework/ ]; then
	echo "Framework directory already exists; bailing out.";
	exit 1;
fi

mkdir Gtk.framework

#
# 2. Create Libraries/ subdirectory, copy all needed libraries in there.
#
echo "Resolving dependencies ...";

if [ -x Gtk.framework/Libraries/ ]; then
	echo "Libraries subdirectory already exists; bailing out.";
	exit 1;
fi

mkdir Gtk.framework/Libraries/

# start with the top_level
cp $top_level ./Gtk.framework/Libraries/
newid=`echo $top_level | sed -e "s@$libprefix@$new_prefix@"`;
install_name_tool -id $newid $newid

# resolve dependencies

cd ./Gtk.framework/Libraries/

files_left=true;
nfiles=0

while $files_left; do
	libs=`ls *dylib`;
	deplibs=`otool -L $libs 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep $libprefix | grep -v $top_level | sort | uniq`;

	for j in $deplibs; do
		j=`echo $j | sed -e "s@$libprefix@@"`;
		j=`echo $j | sed -e "s@^/@@"`;

		cp -f $libprefix/$j .;

		libname=`echo $j | sed -e "s@[\.-0123456789].*@@"`;
		newid=`otool -L ./$j 2>/dev/null | fgrep compatibility | grep $libname | cut -d\( -f1`;
		newid=`echo $newid | sed -e "s@$libprefix@$new_prefix@"`;

		install_name_tool -id $newid ./$j
	done;

	nnfiles=`ls *dylib | wc -l`;
	if [ $nnfiles = $nfiles ]; then
		files_left=false
	else
		nfiles=$nnfiles
	fi
done

cd ../..

#
# 3. Run install_name_tool on all those libraries.
#

echo "Updating install-names..."

cd ./Gtk.framework/Libraries/

libs=`ls *dylib`;
for i in $libs; do
	fixlibs=`otool -L $i 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep $prefix`;

	for j in $fixlibs; do
		new=`echo $j | sed -e s@$libprefix@$new_prefix@`;
		install_name_tool -change $j $new $i;
	done;
done

cd ../..

# 4. Create Headers/ subdirectory, copy all needed header files.

# FIXME: is there any way we can do this without hardcoding?
echo "Copying header files ..."

mkdir ./Gtk.framework/Headers/
cd ./Gtk.framework/Headers/

incprefix="$prefix/include"

cp $incprefix/cairo/*h .

cp -r $incprefix/glib-2.0/glib/ ./glib/
cp -r $incprefix/glib-2.0/glib.h ./glib.h
cp -r $incprefix/glib-2.0/glib-object.h ./glib-object.h
cp $prefix/lib/glib-2.0/include/glibconfig.h ./glibconfig.h
cp -r $incprefix/glib-2.0/gmodule.h ./gmodule.h
cp -r $incprefix/glib-2.0/gobject/ ./gobject/

cp -r $incprefix/pango-1.0/pango/ ./pango/

cp -r $incprefix/atk-1.0/atk/ ./atk/

cp -r $incprefix/gtk-2.0/gdk/ ./gdk/
cp $prefix/lib/gtk-2.0/include/gdkconfig.h ./gdkconfig.h
cp -r $incprefix/gtk-2.0/gdk-pixbuf/ ./gdk-pixbuf/
cp -r $incprefix/gtk-2.0/gtk/ ./gtk/

cd ../..

# 5. Compile Gtk.c into the framework shared library.

echo "Building main Gtk library..."

make
mv ./Gtk ./Gtk.framework/Gtk

# 6. Setting up Pango modules.

echo "Setting up pango modules ..."

mkdir -p Gtk.framework/Resources/etc/pango/

cat <<EOF > "./Gtk.framework/Resources/etc/pango/pangorc"
[Pango]
ModuleFiles=./pango.modules
EOF

sed -e "s@$libprefix@$framework/Resources/lib@" < $prefix/etc/pango/pango.modules > ./Gtk.framework/Resources/etc/pango/pango.modules

mkdir -p Gtk.framework/Resources/lib/pango/1.6.0/modules/
cp $libprefix/pango/1.6.0/modules/*so ./Gtk.framework/Resources/lib/pango/1.6.0/modules/

pushd . > /dev/null
cd ./Gtk.framework/Resources/lib/pango/1.6.0/modules/

libs=`ls *so`;
for i in $libs; do
	fixlibs=`otool -L $i 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep $prefix`;

	for j in $fixlibs; do
		new=`echo $j | sed -e s@$libprefix@$new_prefix@`;
		install_name_tool -change $j $new $i;
	done;
done

popd > /dev/null

# 8. Done?
echo "Finished.";

exit 0;
