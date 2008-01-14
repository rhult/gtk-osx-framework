#!/bin/sh

#
# prepare-for-system.sh -- Prepare a Gtk.framework for installation in
#                          the System's framework directory.
#
# Copyright (C) 2007,2008  Imendio AB
#

print_help()
{
	echo "Usage: `basename $0` <full-path-to-framework>"
	exit 1
}

#
# Verify framework path
#
if [ "x$*" = x ]; then
	print_help
	exit 1
fi

# FIXME: want to check if the path is absolute

framework="$*"

if [ ! -d $framework ]; then
	echo "The directory $* does not exist"
	exit 1
fi

if [ ! -x $framework ]; then
	echo "The framework in $* is not accessible"
	exit 1
fi

#
# Check framework directory for sanity
#

if [ ! -d "$framework"/Headers -o ! -d "$framework"/Libraries -o ! -d "$framework"/Resources -o ! -x "$framework"/Gtk ]; then
	echo "$framework does not seem to be a Gtk.framework"
	exit 1
fi

#
# Do the actual conversion
#

echo "Processing $framework ..."

# Get rid of the trailing slash.
prefix=`dirname "$framework"`/`basename "$framework"`
new_prefix="/Library/Frameworks/Gtk.framework"

# 2. Update main Gtk library.
install_name_tool -id $new_prefix/Gtk $prefix/Gtk

deplibs=`otool -L $prefix/Gtk 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep "$prefix/Libraries" | grep -v "$prefix/Gtk" | sort | uniq`;
for i in $deplibs; do
	new=`echo $i | sed -e "s,$prefix/Libraries/,$new_prefix/Libraries/,"`;
	install_name_tool -change $i $new $prefix/Gtk
done;

# 3. Update ./Libraries
pushd . > /dev/null
cd $prefix/Libraries

libs=`ls *dylib`;
for i in $libs; do
	if [ -h $i ]; then
		continue;
	fi;

	install_name_tool -id $new_prefix/Libraries/$i ./$i

        fixlibs=`otool -L $i 2>/dev/null | fgrep compatibility | cut -d\( -f1 | 
grep "$prefix/Libraries/"`;

        for j in $fixlibs; do
                new=`echo $j | sed -e s,$prefix/Libraries/,$new_prefix/Libraries/,`;
                install_name_tool -change $j $new $i;
        done;
done

popd > /dev/null

# 4. Update pango modules
pushd . > /dev/null
cd $prefix/Resources/lib/pango/1.6.0/modules/

libs=`ls *so`;
for i in $libs; do
        fixlibs=`otool -L $i 2>/dev/null | fgrep compatibility | cut -d\( -f1 | 
grep "$prefix/Libraries/"`;

        for j in $fixlibs; do
                new=`echo $j | sed -e s,$prefix/Libraries/,$new_prefix/Libraries/,`;
                install_name_tool -change $j $new $i;
        done;
done

popd > /dev/null

# 5. Update pango.modules
pushd . > /dev/null
cd $prefix/Resources/etc/pango

mv pango.modules pango.modules.old
sed -e "s,$prefix,$new_prefix," ./pango.modules.old > pango.modules
rm pango.modules.old

popd > /dev/null

echo "Finished."

# Done
exit 0;
