#!/bin/bash
#
# Creates Mac OS X frameworks for GLib, GTK+, Cairo, etc.
#
# Copyright (C) 2007, 2008 Imendio AB
#

# We apply some jhbuild magic to force the use of framework versions
# over the normally installed versions.
#
# Note that the default is to run "make clean" since otherwise we will
# still link against the same old installation.
#
# Also note that it is assumed that everything up to before glib is
# built already, with the cfw-10.4 configuration.
#

# Use the right configuration for jhbuild.
export JHB=cfw-10.4

all_modules="GLib Cairo Gtk Libglade Loudmouth"

PREFIX=`jhbuild getenv JHBUILD_PREFIX`
case "$PREFIX" in
    /*)
        ;;
    *)
        echo "No prefix setup, make sure you have a recent jhbuildrc file from"
        echo " http://developer.imendio.com/projects/gtk-macosx/"
        echo "and a framework creation setup (\".jhbuildrc-$JHB\" file)."
        exit 1
        ;;
esac

print_usage()
{
    echo "Usage: `basename $0` [-fnlh] [FRAMEWORK...]"
    echo "Options:"
    echo "  -f        - Do not rebuild, just recreate the frameworks"
    echo "  -n        - Do not update modules (no network mode)"
    echo "  -l        - Do not run 'make clean' before building"
    echo "  -h        - Display this help text"
    echo "            - FRAMEWORK... is an optional list of frameworks to create"
    echo "              Valid framework names are: $all_modules"
}

create_framework()
{
    framework=$1
    shift 1

    if (echo "$modules" | grep -w $framework) >/dev/null; then
        found_framework=yes
        modules=`echo $modules | sed -e 's/$framework//'`

        if [ $rebuild == yes ]; then
            rm "$PREFIX"/lib/*.la 2>/dev/null
            jhbuild buildone $update $clean $* || exit 1
        fi

        rm -rf $framework.framework
        ./create-$framework-framework.sh $PREFIX || exit 1
    fi

    if [ "x$JHB_PREPEND_FRAMEWORKS" == x ]; then
        export JHB_PREPEND_FRAMEWORKS=`pwd`/$framework.framework
    else
        export JHB_PREPEND_FRAMEWORKS="$JHB_PREPEND_FRAMEWORKS:`pwd`/$framework.framework"
    fi
}

rebuild=yes
update=
clean=-c
while getopts "fnh" o; do
    case "$o" in
        f)
            rebuild=no
            ;;
        n)
            update=-n
            ;;
        l)
            clean=
            ;;
        h)
            print_usage
            exit 0
            ;;
        ?)
            print_usage
            exit 1
            ;;
    esac
done
shift $(($OPTIND - 1))

modules=$*

if [ "x$modules" != x ]; then
    tmp=$modules
    for m in $all_modules; do
        tmp=`echo $tmp | sed -e "s/$m//"`
    done

    if [ "x$tmp" != x ]; then
        echo "Invalid framework names: $tmp"
        exit 1
    fi
else
    modules=$all_modules
fi

create_framework GLib intltool glib

create_framework Cairo pixman cairo

create_framework Gtk atk pango gtk+ gtk-engines ige-mac-integration

create_framework Libglade libglade

create_framework Loudmouth loudmouth
