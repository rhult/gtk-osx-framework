#!/bin/sh

#
# prepare-for-system.sh -- Prepare a Gtk.framework for installation in
#                          the System's framework directory.
#
# Copyright (C) 2007,2008  Imendio AB
#

print_help()
{
	echo "Usage: `basename $0` <path-to-framework>"
	exit 1
}

fix_library_prefixes()
{
	directory=$1
	old_prefix=$2
	new_prefix=$3

	pushd . > /dev/null
	cd $directory

	libs=`ls *so`;
	for i in $libs; do
		fixlibs=`otool -L $i 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep "$old_prefix/Libraries/"`;

		for j in $fixlibs; do
			new=`echo $j | sed -e s,$old_prefix/Libraries/,$new_prefix/Libraries/,`;
			install_name_tool -change $j $new $i;
		done;
	done

	popd > /dev/null
}

update_config()
{
	directory=$1
	config_file=$2
	old_prefix=$3
	new_prefix=$4

	pushd . > /dev/null
	cd $directory

	mv $config_file $config_file".old"
	sed -e "s,$old_prefix,$new_prefix," ./$config_file".old" > $config_file
	rm $config_file".old"

	popd > /dev/null
}

#
# Verify framework path
#
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
framework=`dirname "$framework"`/`basename "$framework"`


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
fix_library_prefixes "$prefix/Resources/lib/pango/1.6.0/modules/" $prefix $new_prefix
update_config "$prefix/Resources/etc/pango" "pango.modules" $prefix $new_prefix

# 5. Update GTK+ modules
fix_library_prefixes "$prefix/Resources/lib/gtk-2.0/2.10.0/engines" $prefix $new_prefix
fix_library_prefixes "$prefix/Resources/lib/gtk-2.0/2.10.0/immodules" $prefix $new_prefix
fix_library_prefixes "$prefix/Resources/lib/gtk-2.0/2.10.0/loaders" $prefix $new_prefix
fix_library_prefixes "$prefix/Resources/lib/gtk-2.0/2.10.0/printbackends" $prefix $new_prefix

update_config "$prefix/Resources/etc/gtk-2.0/" "gdk-pixbuf.loaders" $prefix $new_prefix
update_config "$prefix/Resources/etc/gtk-2.0/" "gtk.immodules" $prefix $new_prefix

# 6. Update pkg-config files
pushd . > /dev/null
cd $prefix/Resources/lib/pkgconfig
files=`ls *pc`;
for i in $files; do
    update_config "$prefix/Resources/lib/pkgconfig/" $i $prefix $new_prefix
done
popd > /dev/null

echo "Finished."

# Done
exit 0;
