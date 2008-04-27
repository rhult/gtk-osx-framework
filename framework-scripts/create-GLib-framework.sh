#!/bin/bash
#
# Creates a Mac OS X framework for GLib.
#
# Copyright (C) 2007, 2008 Imendio AB
#

source ./framework-helpers.sh

# Do initial setup.
init GLib "$*" libglib-2.0.0.dylib
copy_main_library

# Copy in libraries manually since nothing links to it so it's not
# pulled in automatically.
cp "$old_prefix"/lib/libgmodule-2.0.0.dylib "$framework"/Libraries/
cp "$old_prefix"/lib/libgio-2.0.0.dylib "$framework"/Libraries/
cp "$old_prefix"/lib/libgobject-2.0.0.dylib "$framework"/Libraries/
cp "$old_prefix"/lib/libgthread-2.0.0.dylib "$framework"/Libraries/

# Copy in any libraries we depend on.
resolve_dependencies

# "Relink" library dependencies.
fix_library_prefixes "$framework"/Libraries "$old_prefix"/lib "$new_prefix"

# Copy header files.
copy_headers \
    include/glib-2.0 glib \
    include/glib-2.0 glib.h \
    include/glib-2.0 glib-object.h \
    lib/glib-2.0/include glibconfig.h \
    include/glib-2.0 gmodule.h \
    include/glib-2.0 gobject \
    include/glib-2.0 gio

# Copy and update our "fake" pkgconfig files.
copy_pc_files "gio-2.0.pc gio-unix-2.0.pc glib-2.0.pc gmodule-2.0.pc gmodule-export-2.0.pc gmodule-no-export-2.0.pc gobject-2.0.pc gthread-2.0.pc"

# Create the library that will be the main framework library.
build_framework_library

# Special-case libintl so that dependencies don't pick it up.
# FIXME: Doesn't seem to work though..
ln -s "$framework"/GLib "$framework"/Resources/atlib/libintl.8.dylib || exit 1

# Copy executables.

# This is work in progress, needs some more work. We also need to copy
# in m4 files etc and setup such paths in order to be able to build
# autotools projects completely against those frameworks.

fix_executable_prefixes()
{
    echo "Updating library names in executables..."

    local directory=$1
    local libs=$2
    local old_prefix=$3
    local new_prefix=$4

    pushd . >/dev/null
    cd $directory

    for i in $libs; do
	fixlibs=`otool -L $i 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep "$old_prefix"`

	for j in $fixlibs; do
	    new=`echo $j | sed -e s@$old_prefix@$new_prefix@`
	    install_name_tool -change "$j" "$new" "$i" || exit 1
	done
    done

    popd >/dev/null
}

mkdir "$framework"/Resources/bin
cp "$old_prefix"/bin/glib-genmarshal "$framework"/Resources/bin
fix_executable_prefixes "$framework"/Resources/bin glib-genmarshal "$old_prefix"/lib "$new_prefix"
#JHB=fw jhbuild shell

echo "Done."
