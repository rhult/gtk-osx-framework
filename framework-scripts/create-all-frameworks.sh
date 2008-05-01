#!/bin/bash
#
# Creates Mac OS X frameworks for GLib, GTK+, Cairo, etc.
#
# Copyright (C) 2007, 2008 Imendio AB
#

# We apply some magic to force the use of framework versions over the
# normally installed versions. Also do a make clean since otherwise we
# will still link against the same old installation.
#
# NOTE: We assume everything up to before glib is built already, with
# the cfw-10.4 configuration.
#

# Use the right configuration for jhbuild.
export JHB=cfw-10.4

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

# Make it possble to not update modules, makes for quicker rebuilding.
if [ x$SKIP_UPDATE != x -o x$SKIP_BUILD != x ]; then
    SKIP_UPDATE="-n"
fi

build()
{
    if [ x$SKIP_BUILD == x ]; then
        rm "$PREFIX"/lib/*.la 2>/dev/null
        jhbuild buildone $SKIP_UPDATE -c $* || exit 1
    fi
}

create_framework()
{
    rm -rf $1.framework
    ./create-$1-framework.sh $PREFIX || exit 1

    if [ "x$JHB_PREPEND_FRAMEWORKS" == x ]; then
        export JHB_PREPEND_FRAMEWORKS=`pwd`/$1.framework
    else
        export JHB_PREPEND_FRAMEWORKS="$JHB_PREPEND_FRAMEWORKS:`pwd`/$1.framework"
    fi
}

export MACOSX_DEPLOYMENT_TARGET=10.4

build glib
create_framework GLib

build pixman
build cairo
create_framework Cairo

build atk
build pango
build gtk+
build gtk-engines
build ige-mac-integration
create_framework Gtk

build libglade
create_framework Libglade

build loudmouth
create_framework Loudmouth
