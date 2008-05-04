#!/bin/bash
#
# Creates a Mac OS X framework for GLib.
#
# Copyright (C) 2007, 2008 Imendio AB
#

source ./framework-helpers.sh

copy_gettext_libraries()
{
    echo "Copying gettext libraries..."

    src=libgettextsrc-0.16.dylib
    lib=libgettextlib-0.16.dylib

    from="$old_prefix"/lib
    to="$framework"/Resources/dev/lib

    cp "$from"/$src "$to"
    cp "$from"/$lib "$to"

    install_name_tool -change "$from"/$src "$to"/$src "$to"/$lib
    install_name_tool -change "$from"/$lib "$to"/$lib "$to"/$src

    install_name_tool -id "$to"/$lib "$to"/$lib
    install_name_tool -id "$to"/$src "$to"/$src
}

copy_gettext_executables()
{
    echo "Copying gettext tools..."

    dest="$framework"/Resources/dev/bin
    mkdir -p "$dest"

    execs="msgattrib msgcmp msgconv msgexec msgfmt msginit msgunfmt msgcat msgcomm msgen msgfilter msggrep msgmerge msguniq xgettext ngettext"
    for exe in $execs; do
        full_path="$old_prefix"/bin/$exe
        cp "$full_path" "$dest"

        if [ "x`file "$full_path" | grep Mach-O\ executable`" != x ]; then
            fixlibs=`otool -L "$full_path" 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep "$old_prefix"/lib`
	    for j in $fixlibs; do
	        new=`echo $j | sed -e s@$old_prefix/lib/libgettextsrc-0.16.dylib@$framework/Resources/dev/lib/libgettextsrc-0.16.dylib@ -e s@$old_prefix/lib/libgettextlib-0.16.dylib@$framework/Resources/dev/lib/libgettextlib-0.16.dylib@ -e s@$old_prefix/lib@$new_prefix@`
	        install_name_tool -change "$j" "$new" "$dest"/$exe || do_exit 1
	    done
        fi
    done
}

copy_intltool()
{
    echo "Copying intltool tools..."

    dest="$framework"/Resources/dev/bin
    mkdir -p "$dest"

    execs="intltool-extract intltool-merge intltool-prepare intltool-update intltoolize"
    for exe in $execs; do
        full_path="$old_prefix"/bin/$exe
        cp "$full_path" "$dest"
        update_dev_file "$dest"/$exe
    done

    mkdir -p "$framework"/Resources/dev/share
    cp -r "$old_prefix"/share/intltool "$framework"/Resources/dev/share/
}

# Do initial setup.
init GLib "$*" libglib-2.0.0.dylib
copy_main_library

# Copy in libraries manually since nothing links to them so they are
# not pulled in automatically.
cp "$old_prefix"/lib/libgmodule-2.0.0.dylib "$framework"/Libraries/
cp "$old_prefix"/lib/libgio-2.0.0.dylib "$framework"/Libraries/
cp "$old_prefix"/lib/libgobject-2.0.0.dylib "$framework"/Libraries/
cp "$old_prefix"/lib/libgthread-2.0.0.dylib "$framework"/Libraries/

# Copy in any libraries we depend on.
resolve_dependencies

# "Relink" library dependencies.
fix_library_prefixes "$framework"/Libraries

# Copy header files.
copy_headers \
    include/glib-2.0 glib \
    include/glib-2.0 glib.h \
    include/glib-2.0 glib-object.h \
    lib/glib-2.0/include glibconfig.h \
    include/glib-2.0 gmodule.h \
    include/glib-2.0 gobject \
    include/glib-2.0 gio \
    include libintl.h

# Copy and update our "fake" pkgconfig files.
copy_pc_files "gio-2.0.pc gio-unix-2.0.pc glib-2.0.pc gmodule-2.0.pc gmodule-export-2.0.pc gmodule-no-export-2.0.pc gobject-2.0.pc gthread-2.0.pc"

# Create the library that will be the main framework library.
build_framework_library

# Special-case libintl so that dependencies don't pick it up.
ln -s "$framework"/GLib "$framework"/Resources/dev/lib/libintl.dylib || do_exit 1

# Copy glib executables.
copy_dev_executables glib-genmarshal glib-gettextize glib-mkenums
update_dev_file "$framework"/Resources/dev/bin/glib-gettextize

# Gettext binaries are handled specially, since they are only used for
# development but also needs libraries.
copy_gettext_libraries
fix_library_prefixes "$framework"/Resources/dev/lib
copy_gettext_executables

# Copy gettext data.
mkdir -p "$framework"/Resources/dev/share
cp -r "$old_prefix"/share/glib-2.0 "$framework"/Resources/dev/share/

# Copy intltool scripts and data.
copy_intltool

# Copy aclocal macros.
copy_aclocal_macros glib-2.0.m4 glib-gettext.m4 intltool.m4

echo "Done."
