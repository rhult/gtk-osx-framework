#!/bin/sh

#
# prepare-for-app-bundle.sh -- Prepare a Gtk.framework for inclusion in
#                              an application bundle.
#
# Copyright (C) 2007, 2008  Imendio AB
#
#

framework="/Library/Frameworks/Gtk.framework"
new_framework="./Gtk.framework"

if [ ! -d $framework ]; then
	echo "The directory $framework does not exist"
	exit 1
fi

if [ ! -x $framework ]; then
	echo "The framework in $framework is not accessible"
	exit 1
fi

if [ -x $new_framework ]; then
	echo "$new_framework already exists; bailing out"
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
# Create a copy of the system framework
#

echo "Copying ..."
# FIXME: we might want to exclude all the header files when copying.
cp -r $framework $new_framework

#
# Do the actual conversion
#

echo "Processing $new_framework ..."

# Get rid of the trailing slash.
prefix=$framework
new_prefix=@executable_path/../Frameworks/Gtk.framework

# 2. Update main Gtk library.
install_name_tool -id $new_prefix/Gtk $new_framework/Gtk

deplibs=`otool -L $prefix/Gtk 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep "$prefix/Libraries" | grep -v "$prefix/Gtk" | sort | uniq`;
for i in $deplibs; do
	new=`echo $i | sed -e "s,$prefix/Libraries/,$new_prefix/Libraries/,"`;
	install_name_tool -change $i $new $new_framework/Gtk
done;

# 3. Update ./Libraries
pushd . > /dev/null
cd $new_framework/Libraries

libs=`ls *dylib`;
for i in $libs; do
	if [ -h $i ]; then
		continue;
	fi;

	install_name_tool -id $new_prefix/$i ./$i

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
cd $new_framework/Resources/lib/pango/1.6.0/modules/

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
cd $new_framework/Resources/etc/pango

mv pango.modules pango.modules.old
sed -e "s,$prefix,$new_prefix," ./pango.modules.old > pango.modules
rm pango.modules.old

popd > /dev/null


echo "Finished."
echo -ne "\n\n"
echo "When embedding into an application bundle yourself, do not forget to"
echo "update your binary using:"
echo "  install_name_tool -change $prefix/Gtk $new_prefix/Gtk <binary>"
echo ""

# Done
exit 0;
