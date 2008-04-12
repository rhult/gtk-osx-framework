#!/bin/bash

#
# create-framework.sh  --  Create an OS X Gtk.framework out of a
#                          GTK+ installed in a prefix.
#
# Copyright (C) 2007, 2008  Imendio AB
#

# Constants
starting_point="libgtk-quartz-2.0.0.dylib";

# Helper functions

print_help()
{
	echo "Usage: `basename $0` <prefix>"
	exit 1
}

fix_library_prefixes()
{
	directory=$1;
	old_prefix=$2;
	new_prefix=$3;

	pushd . > /dev/null
	cd $directory

	libs=`ls *{so,dylib} 2>/dev/null`;
	for i in $libs; do
		fixlibs=`otool -L $i 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep $prefix`;

		for j in $fixlibs; do
			new=`echo $j | sed -e s@$old_prefix@$new_prefix@`;
			install_name_tool -change $j $new $i;
		done;
	done

	popd > /dev/null
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
# - Create Gtk.framework directory.
#
echo "Creating framework in ./Gtk.framework ..."

if [ -x Gtk.framework/ ]; then
	echo "Framework directory already exists; bailing out.";
	exit 1;
fi

mkdir Gtk.framework

#
# - Create Libraries/ subdirectory, copy the toplevel library
#
echo "Creating Libraries/ ...";

if [ -x Gtk.framework/Libraries/ ]; then
	echo "Libraries subdirectory already exists; bailing out.";
	exit 1;
fi

mkdir Gtk.framework/Libraries/

# start with the top_level
cp $top_level ./Gtk.framework/Libraries/
newid=`echo $top_level | sed -e "s@$libprefix@$new_prefix@"`;
install_name_tool -id $newid $newid

#
# - Create Headers/ subdirectory, copy all needed header files.
#

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
cp -r $incprefix/glib-2.0/gio/ ./gio/

cp -r $incprefix/pango-1.0/pango/ ./pango/

cp -r $incprefix/atk-1.0/atk/ ./atk/

cp -r $incprefix/gtk-2.0/gdk/ ./gdk/
cp $prefix/lib/gtk-2.0/include/gdkconfig.h ./gdkconfig.h
cp -r $incprefix/gtk-2.0/gdk-pixbuf/ ./gdk-pixbuf/
cp -r $incprefix/gtk-2.0/gtk/ ./gtk/

cp -r $incprefix/igemacintegration/ .

cd ../..

#
# - Setting up Pango modules.
#

echo "Setting up Pango modules ..."

mkdir -p Gtk.framework/Resources/etc/pango/

cat <<EOF > "./Gtk.framework/Resources/etc/pango/pangorc"
[Pango]
ModuleFiles=./pango.modules
EOF

sed -e "s@$libprefix@$framework/Resources/lib@" < $prefix/etc/pango/pango.modules > ./Gtk.framework/Resources/etc/pango/pango.modules

mkdir -p Gtk.framework/Resources/lib/pango/1.6.0/modules/
cp $libprefix/pango/1.6.0/modules/*so ./Gtk.framework/Resources/lib/pango/1.6.0/modules/

#
# - Setting up GTK+ modules
#
echo "Setting up GTK+ modules ..."

mkdir -p Gtk.framework/Resources/etc/gtk-2.0

sed -e "s@$libprefix@$framework/Resources/lib@" < $prefix/etc/gtk-2.0/gdk-pixbuf.loaders > ./Gtk.framework/Resources/etc/gtk-2.0/gdk-pixbuf.loaders
sed -e "s@$libprefix@$framework/Resources/lib@" < $prefix/etc/gtk-2.0/gtk.immodules > ./Gtk.framework/Resources/etc/gtk-2.0/gtk.immodules

mkdir -p Gtk.framework/Resources/lib/gtk-2.0/2.10.0/{engines,immodules,loaders,printbackends}

# FIXME: copying all engines for now
cp -r $libprefix/gtk-2.0/2.10.0/engines/*so ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/engines
cp $libprefix/gtk-2.0/2.10.0/immodules/*so ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/immodules
cp $libprefix/gtk-2.0/2.10.0/loaders/*so ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/loaders
cp $libprefix/gtk-2.0/2.10.0/printbackends/*so ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/printbackends

#
# - Copy in additional support libraries
#
echo "Copying support libraries ..."

cp -r $libprefix/libigemacintegration.0.dylib ./Gtk.framework/Libraries/

#
# - Copy pkg-config files
#

# FIXME


#
# - Resolve dependencies
#
echo "Resolving dependencies ..."

files_left=true;
nfiles=0

while $files_left; do
	libs=`ls ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/loaders/*so \
	 ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/printbackends/*so \
	 ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/immodules/*so \
	 ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/engines/*so \
	 ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/modules/*so \
	 ./Gtk.framework/Libraries/*dylib 2>/dev/null`;
	deplibs=`otool -L $libs 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep $libprefix | grep -v $top_level | sort | uniq`;

	# Copy library and correct ID
	for j in $deplibs; do
		j=`echo $j | sed -e "s@$libprefix@@"`;
		j=`echo $j | sed -e "s@^/@@"`;

		cp -f $libprefix/$j ./Gtk.framework/Libraries;

		libname=`echo $j | sed -e "s@[\.-0123456789].*@@"`;
		newid=`otool -L ./Gtk.framework/Libraries/$j 2>/dev/null | fgrep compatibility | grep $libname | cut -d\( -f1`;
		newid=`echo $newid | sed -e "s@$libprefix@$new_prefix@"`;

		install_name_tool -id $newid ./Gtk.framework/Libraries/$j
	done;

	nnfiles=`ls ./Gtk.framework/Libraries/*dylib | wc -l`;
	if [ $nnfiles = $nfiles ]; then
		files_left=false
	else
		nfiles=$nnfiles
	fi
done

#
# - Update gdk-pixbuf library name.
#
echo "Updating gdk-pixbuf library name ..."

# Change the name of gdk-pixbuf library to use a dash instead of
# underscore, to work around an issue with how OS X interprets library
# names when using sublibraries.
#

newid=`pwd`/Gtk.framework/Libraries/libgdk-pixbuf-2.0.0.dylib
mv ./Gtk.framework/Libraries/libgdk_pixbuf-2.0.0.dylib $newid
install_name_tool -id $newid $newid

files_left=true;
nfiles=0

libs=`ls ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/loaders/*so \
    ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/printbackends/*so \
    ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/immodules/*so \
    ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/engines/*so \
    ./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/modules/*so \
    ./Gtk.framework/Libraries/*dylib 2>/dev/null`
for lib in $libs; do
    match=`otool -L $lib 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep $libprefix | grep libgdk_pixbuf-2.0.0`;
    if [ "x$match" != x ]; then
        install_name_tool -change $match $newid $lib
    fi
done

#
# - Run install_name_tool on all those libraries.
#
echo "Updating install-names..."

fix_library_prefixes "./Gtk.framework/Libraries" $libprefix $new_prefix

# Fix the prefixes
fix_library_prefixes "./Gtk.framework/Resources/lib/pango/1.6.0/modules" $libprefix $new_prefix

fix_library_prefixes "./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/engines" $libprefix $new_prefix
fix_library_prefixes "./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/immodules" $libprefix $new_prefix
fix_library_prefixes "./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/loaders" $libprefix $new_prefix
fix_library_prefixes "./Gtk.framework/Resources/lib/gtk-2.0/2.10.0/printbackends" $libprefix $new_prefix

#
# -  Create and install pkg-config files.
#
echo "Creating and copying pkg-config files ..."

escaped_framework=`echo $framework | sed -e 's@\/@\\\/@g' -e 's@\.@\\\.@g'`

files="atk.pc gdk-2.0.pc gdk-pixbuf-2.0.pc gdk-quartz-2.0.pc gio-2.0.pc gio-unix-2.0.pc glib-2.0.pc gmodule-2.0.pc gmodule-export-2.0.pc gmodule-no-export-2.0.pc gobject-2.0.pc gthread-2.0.pc gtk+-2.0.pc gtk+-quartz-2.0.pc gtk+-unix-print-2.0.pc pango.pc pangocairo.pc ige-mac-integration.pc"

mkdir -p $framework/Resources/lib/pkgconfig

# Point all the pc files to our framework library.
for pc in $files; do
    cat $prefix/lib/pkgconfig/$pc | sed \
        -e "s/\(^prefix=\).*/\1$escaped_framework\/Resources/" \
        -e "s/\(^Requires:\).*/\1/" \
        -e "s/\(^Libs:\).*/\1 -framework Gtk/" \
        -e "s/\(^Cflags:\).*/\1 -I$escaped_framework\/Headers/" > $framework/Resources/lib/pkgconfig/$pc
done


#
# - Compile Gtk.c into the framework shared library.
#
echo "Building main Gtk library..."

make
mv ./Gtk ./Gtk.framework/Gtk

#
# - Put Info.plist in place; set up small gtkrc
#
cp ./Info.plist ./Gtk.framework/Resources/Info.plist

cat <<EOF > "./Gtk.framework/Resources/etc/gtk-2.0/gtkrc"
gtk-icon-theme-name = "Tango"
gtk-font-name = "Lucida Grande 12"
gtk-enable-mnemonics = 0
EOF

#
# - Done?
#
echo "Finished.";

exit 0;
