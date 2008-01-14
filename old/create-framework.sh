#!/bin/bash

#
# Copyright (C) 2007, 2008  Imendio AB
#

top_level="/opt/lib/libgtk-quartz-2.0.0.1500.0.dylib";
prefix="/opt/lib";
new_prefix="/Users/kris/src/gtk-framework/Gtk.framework/Libraries";

if [ ! -x $top_level ]; then
	echo "Cannot read $top_level; bailing out.";
	exit 1;
fi;

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

# resolve dependencies

cd ./Gtk.framework/Libraries/

files_left=true;
nfiles=0

while $files_left; do
	libs=`ls *dylib`;
	deplibs=`otool -L $libs 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep $prefix | grep -v $top_level | sort | uniq`;

	for j in $deplibs; do
		while [ -h $j ]; do
			j=`readlink $j`;
		done;

		j=`echo $j | sed -e "s@$prefix@@"`;

		cp -f $prefix/$j .;

		libname=`echo $j | sed -e "s@[\.-0123456789].*@@"`;
		newid=`otool -L ./$j 2>/dev/null | fgrep compatibility | grep $libname | cut -d\( -f1`;
		newid=`echo $newid | sed -e "s@$prefix@/Users/kris/src/gtk-framework/Gtk.framework/Libraries@"`;

		install_name_tool -id $newid ./$j
	done;

	nnfiles=`ls *dylib | wc -l`;
	if [ $nnfiles = $nfiles ]; then
		files_left=false
	else
		nfiles=$nnfiles
	fi
done

libs=`ls *dylib`;
for i in $libs; do
	libname=`echo "$i" | sed -e "s@[\.-0123456789].*@@"`;

	links=`ls $prefix/$libname*dylib`;

	for j in $links; do
		if [ ! -h $j ]; then
			continue;
		fi;

		source=`echo $j | sed -e "s@$prefix/@@"`;
		target=`readlink $j`;

		ln -s $target $source;
	done
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
		new=`echo $j | sed -e s@$prefix@$new_prefix@`;
		install_name_tool -change $j $new $i;
	done;
done

cd ../..

# 4. Create Headers/ subdirectory, copy all needed header files.

# FIXME: is there any way we can do this without hardcoding?
echo "Copying header files ..."

mkdir ./Gtk.framework/Headers/
cd ./Gtk.framework/Headers/

cp /opt/include/cairo/*h .

cp -r /opt/include/glib-2.0/glib/ ./glib/
cp -r /opt/include/glib-2.0/glib.h ./glib.h
cp -r /opt/include/glib-2.0/glib-object.h ./glib-object.h
cp /opt/lib/glib-2.0/include/glibconfig.h ./glibconfig.h
cp -r /opt/include/glib-2.0/gmodule.h ./gmodule.h
cp -r /opt/include/glib-2.0/gobject/ ./gobject/

cp -r /opt/include/pango-1.0/pango/ ./pango/

cp -r /opt/include/atk-1.0/atk/ ./atk/

cp -r /opt/include/gtk-2.0/gdk/ ./gdk/
cp /opt/lib/gtk-2.0/include/gdkconfig.h ./gdkconfig.h
cp -r /opt/include/gtk-2.0/gdk-pixbuf/ ./gdk-pixbuf/
cp -r /opt/include/gtk-2.0/gtk/ ./gtk/

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

sed -e "s@$prefix@/Users/kris/src/gtk-framework/Gtk.framework/Resources/lib@" < /opt/etc/pango/pango.modules > ./Gtk.framework/Resources/etc/pango/pango.modules

mkdir -p Gtk.framework/Resources/lib/pango/1.6.0/modules/
cp $prefix/pango/1.6.0/modules/*so ./Gtk.framework/Resources/lib/pango/1.6.0/modules/

pushd .
cd ./Gtk.framework/Resources/lib/pango/1.6.0/modules/

libs=`ls *so`;
for i in $libs; do
	fixlibs=`otool -L $i 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep $prefix`;

	for j in $fixlibs; do
		new=`echo $j | sed -e s@$prefix@$new_prefix@`;
		install_name_tool -change $j $new $i;
	done;
done

popd

# 8. Done?
echo "Finished.";

exit 0;
