#!/bin/bash
#
# Creates a Mac OS X framework for WebKit.
#
# Copyright (C) 2007, 2008 Imendio AB
#

source ./framework-helpers.sh

# Do initial setup.
init WebKitGtk "1" "$*" libwebkit-1.0.dylib
copy_single_main_library

# Copy in any libraries we depend on.
resolve_dependencies

# "Relink" library dependencies.
fix_library_references

# Copy header files.
copy_headers \
    include/webkit-1.0 JavaScriptCore \
    include/webkit-1.0 webkit

# Copy and update our "fake" pkgconfig files.
copy_pc_files "webkit-1.0.pc"

echo "Done."
