#!/bin/bash
#
# Creates a Mac OS X framework for GTK+.
#
# Copyright (C) 2007, 2008 Imendio AB
#

source ./framework-helpers.sh

# Do initial setup.
init Gtk "2" "$*" libgtk-quartz-2.0.0.dylib
copy_main_library

# Copy header files.
copy_headers \
    include/pango-1.0 pango \
    include/atk-1.0 atk \
    include/gtk-2.0 gdk \
    lib/gtk-2.0/include gdkconfig.h \
    include/gtk-2.0 gdk-pixbuf \
    include/gtk-2.0 gtk \
    include/igemacintegration .

# Set up pango.
echo "Setting up Pango modules..."
mkdir -p "$framework"/Resources/etc/pango/
mkdir -p "$framework"/Resources/lib/pango/1.6.0/modules/

cat <<EOF > "$framework/Resources/etc/pango/pangorc"
[Pango]
ModuleFiles=./pango.modules
EOF

sed -e "s@$old_prefix/lib@$framework/Versions/$version/Resources/lib@" < "$old_prefix"/etc/pango/pango.modules > "$framework"/Resources/etc/pango/pango.modules

# Note: Skip copying modules for now, we include the ATSUI module inside pango.
# cp "$old_prefix"/lib/pango/1.6.0/modules/*so "$framework"/Resources/lib/pango/1.6.0/modules/

# Set up GTK+.
echo "Setting up GTK+ modules ..."
mkdir -p "$framework"/Resources/etc/gtk-2.0
mkdir -p "$framework"/Resources/lib/gtk-2.0/2.10.0/{engines,immodules,loaders,printbackends}

sed -e "s@$old_prefix/lib@$framework/Versions/$version/Resources/lib@" < "$old_prefix"/etc/gtk-2.0/gdk-pixbuf.loaders > "$framework"/Resources/etc/gtk-2.0/gdk-pixbuf.loaders
sed -e "s@$old_prefix/lib@$framework/Versions/$version/Resources/lib@" < "$old_prefix"/etc/gtk-2.0/gtk.immodules > "$framework"/Resources/etc/gtk-2.0/gtk.immodules

# Copy modules.
cp "$old_prefix"/lib/gtk-2.0/2.10.0/engines/libclearlooks.so "$framework"/Resources/lib/gtk-2.0/2.10.0/engines
cp "$old_prefix"/lib/gtk-2.0/2.10.0/immodules/*so "$framework"/Resources/lib/gtk-2.0/2.10.0/immodules
cp "$old_prefix"/lib/gtk-2.0/2.10.0/loaders/*so "$framework"/Resources/lib/gtk-2.0/2.10.0/loaders
cp "$old_prefix"/lib/gtk-2.0/2.10.0/printbackends/*so "$framework"/Resources/lib/gtk-2.0/2.10.0/printbackends

# Copy mac integration library.
echo "Copying support libraries ..."
cp "$old_prefix"/lib/libigemacintegration.0.dylib "$framework"/Libraries/

# Copy in any libraries we depend on.
resolve_dependencies

# Rename gdk_pixbuf to gdk-pixbuf to work with sublibraries.
echo "Updating gdk-pixbuf library name ..."
newid="$framework"/Versions/$version/Libraries/libgdk-pixbuf-2.0.0.dylib
mv "$framework"/Libraries/libgdk_pixbuf-2.0.0.dylib "$newid"
install_name_tool -id "$newid" "$newid"

files_left=true
nfiles=0

libs1=`find $framework_name.framework/Versions/$version/Resources/lib -name "*.dylib" -o -name "*.so" 2>/dev/null`
libs2=`find $framework_name.framework/Versions/$version/Libraries -name "*.dylib" -o -name "*.so" 2>/dev/null`
for lib in $libs1 $libs2; do
    match=`otool -L "$lib" 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep "$old_prefix"/lib | grep libgdk_pixbuf-2.0.0`
    if [ "x$match" != x ]; then
        install_name_tool -change "$old_prefix"/lib/libgdk_pixbuf-2.0.0.dylib "$old_prefix"/lib/libgdk-pixbuf-2.0.0.dylib "$lib"
    fi
done

# "Relink" library dependencies.
fix_library_references

# Copy and update our "fake" pkgconfig files.
copy_pc_files "atk.pc pango.pc gdk-pixbuf-2.0.pc"
copy_pc_files "pangocairo.pc"
copy_pc_files "gdk-2.0.pc gdk-quartz-2.0.pc"
copy_pc_files "gtk+-2.0.pc gtk+-quartz-2.0.pc gtk+-unix-print-2.0.pc"
copy_pc_files "ige-mac-integration.pc"

# Create the library that will be the main framework library.
build_framework_library

# Copy executables.
copy_dev_executables \
    gtk-builder-convert \
    gtk-demo \
    gtk-query-immodules-2.0 \
    gtk-update-icon-cache \
    gdk-pixbuf-csource \
    gdk-pixbuf-query-loaders \
    pango-querymodules

# Copy aclocal macros.
copy_aclocal_macros gtk-2.0.m4

# Possibly copy theming data.
if [ x$SKIP_THEMES = x ]; then
    echo "Copying widget and icon theme data ..."

    mkdir -p "$framework"/Resources/share/icons
    mkdir -p "$framework"/Resources/share/themes

    cp -R "$old_prefix"/share/icons/hicolor "$framework"/Resources/share/icons/
    cp -R "$old_prefix"/share/icons/gnome "$framework"/Resources/share/icons/
    "$old_prefix"/bin/gtk-update-icon-cache -f "$framework"/Resources/share/icons/hicolor 2>/dev/null || do_exit 1 "Could not update icon cache. Exiting."
    "$old_prefix"/bin/gtk-update-icon-cache -f "$framework"/Resources/share/icons/gnome 2>/dev/null || do_exit 1 "Could not update icon cache. Exiting."

    #cp -R "$old_prefix"/share/icons/Tango "$framework"/Resources/share/icons/
    #"$old_prefix"/bin/gtk-update-icon-cache -f "$framework"/Resources/share/icons/Tango 2>/dev/null

    cp -R "$old_prefix"/share/themes/Clearlooks "$framework"/Resources/share/themes
else
    echo "Skipping theme data ..."
fi

# Handle style defaults.
echo "Setting up GTK+ theme and settings..."
cp data/gtkrc "$framework"/Resources/etc/gtk-2.0/gtkrc
mkdir -p "$framework"/Resources/share/themes/Mac/gtk-2.0-key
cp data/gtkrc.key.mac "$framework"/Resources/share/themes/Mac/gtk-2.0-key/gtkrc

echo "Done."
