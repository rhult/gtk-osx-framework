#!/bin/bash
#
# Creates a Mac OS X framework for Cairo (pixman included).
#
# Copyright (C) 2007, 2008 Imendio AB
#

source ./framework-helpers.sh

# Do initial setup.
init Cairo "1" "$*" libcairo.2.dylib
copy_main_library

# Copy in any libraries we depend on.
resolve_dependencies

# "Relink" library dependencies.
fix_library_references

# Copy header files.
copy_headers \
    include/cairo .  \
    include/pixman-1 .

# Copy and update our "fake" pkgconfig files.
copy_pc_files "pixman-1.pc cairo-pdf.pc cairo-ps.pc cairo-svg.pc cairo-quartz.pc cairo.pc cairo-quartz-font.pc"

# We don't want anything to drag in libpng, no need to, so override
# requires here. Not sure if this is right really.
copy_pc_files "cairo-png.pc" cairo

# Create the library that will be the main framework library.
build_framework_library

echo "Done."
