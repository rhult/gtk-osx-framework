#!/bin/bash
#
# Prepares a framework for installation in /Library/Frameworks/.
#
# Copyright (C) 2007, 2008 Imendio AB
#

print_help()
{
    echo "Usage: `basename $0` <path-to-framework>"
    exit 1
}

update_config_file()
{
    local file=$1

    if [ ! -f "$file" ]; then
        return
    fi

    sed -e "s,$old_root,$new_root," "$file" > "$file.tmp" || exit 1
    mv "$file.tmp" "$file"
}

# Verify framework path.
if [ "x$*" = x ]; then
    print_help
    exit 1
fi

framework="$*"

# Check the path, and turn it into an absolute path if not absolute
# already.
if [ x`echo "$framework" | sed -e 's@\(^\/\).*@@'` != x ]; then
    framework=`pwd`/$framework
fi

if [ ! -d $framework ]; then
    echo "The directory $* does not exist"
    exit 1
fi

if [ ! -x $framework ]; then
    echo "The framework in $* is not accessible"
    exit 1
fi

# Drop any trailing slash.
basename=`basename "$framework"`
framework=`dirname "$framework"`/$basename

framework_name=`echo $basename | sed -e 's@\(^.*\)\..*@\1@'`

# Check framework directory for sanity.
if [ ! -d "$framework"/Headers -o ! -d "$framework"/Resources -o ! -f "$framework/$framework_name" ]; then
    echo "$framework does not seem to be a valid framework"
    exit 1
fi

old_root=`dirname "$framework"`
new_root="/Library/Frameworks"

echo "Update library references in libraries..."
libs=`find "$framework" \( -name "*.dylib" -o -name "*.so" -o -name "$framework_name" \) -a -type f`
for lib in $libs; do
    new=`echo $lib | sed -e s,$old_root,$new_root,`
    install_name_tool -id "$new" "$lib" || exit 1

    deps=`otool -L $lib 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep "$old_root" | sort | uniq`
    for dep in $deps; do
        new=`echo $dep | sed -e s,$old_root,$new_root,`
        install_name_tool -change "$dep" "$new" "$lib" || exit 1
    done
done

echo "Update library references in executables..."
execs=`find "$framework"/Resources/dev/bin 2>/dev/null`
for exe in $execs; do
    if [ "x`file "$exe" | grep Mach-O\ executable`" != x ]; then
        deps=`otool -L $exe 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep "$old_root" | sort | uniq`
        for dep in $deps; do
            new=`echo $dep | sed -e s,$old_root,$new_root,`
            install_name_tool -change "$dep" "$new" "$exe" || exit 1
        done
    fi
done

echo "Update config files..."
update_config_file "$framework"/Resources/etc/pango/pango.modules
update_config_file "$framework"/Resources/etc/gtk-2.0/gdk-pixbuf.loaders
update_config_file "$framework"/Resources/etc/gtk-2.0/gtk.immodules

echo "Update pkg-config files..."
files=`ls "$framework"/Resources/dev/lib/pkgconfig/*.pc`
for file in $files; do
    update_config_file "$framework"/Resources/dev/lib/pkgconfig/`basename "$file"`
done

echo "Done."
