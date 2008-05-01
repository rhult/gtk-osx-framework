#
# Helper functions for the framework creation scripts.
#
# Copyright (C) 2007, 2008 Imendio AB
#

print_help()
{
    echo "Usage: `basename $0` <prefix>"
    exit 1
}

fix_library_prefixes()
{
    echo "Updating library names..."

    directory=$1
    from="$old_prefix"/lib
    to="$new_prefix"

    pushd . >/dev/null
    cd $directory

    libs=`ls *{so,dylib} 2>/dev/null`
    for i in $libs; do
	fixlibs=`otool -L $i 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep "$from"`

	for j in $fixlibs; do
	    new=`echo $j | sed -e s@$from@$to@`
	    install_name_tool -change "$j" "$new" "$i" || exit 1
	done
    done

    popd >/dev/null
}

init()
{
    if [ x"$2" = x ]; then
	print_help
	exit 1
    fi

    if [ ! -d "$2" ]; then
	echo "The directory $2 does not exist"
	exit 1
    fi

    if [ ! -x "$2" ]; then
	echo "The framework in $2 is not accessible"
	exit 1
    fi

    # Drop any trailing slash.
    old_prefix=`dirname "$2"`/`basename "$2"`
    old_prefix=`echo $old_prefix | sed -e "s@//@/@"`

    main_library="$old_prefix/lib/$3"

    if [ ! -x "$main_library" ]; then
	echo "Required library $main_library does not exist."
	exit 1
    fi

    framework_name="$1"

    framework="`pwd`/$framework_name.framework"
    new_prefix="$framework/Libraries"

    if [ -x $framework ]; then
	echo "Framework directory already exists; bailing out."
	exit 1
    fi

    echo "Creating $framework_name.framework skeleton..."

    mkdir -p "$framework"
    mkdir "$framework"/Libraries
    mkdir "$framework"/Resources
    mkdir "$framework"/Headers

    cp Info-$framework_name.plist "$framework"/Resources/Info.plist || exit 1
}

copy_main_library()
{
    echo "Copying main library..."

    cp $main_library "$framework"/Libraries/
    newid=`echo "$main_library" | sed -e "s@$old_prefix/lib@$new_prefix@"`
    install_name_tool -id "$newid" "$newid" || exit 1
}

symlink_framework_library()
{
    # This symlink is used to build any autotool based modules. Since
    # the install name points to the framework library, the
    # dependencies will end up right, but libtool needs a name on the
    # form "libfoo.dylib". The pkg-config file points to this
    # directory and library.
    mkdir -p "$framework"/Resources/dev/lib
    ln -s "$framework"/$framework_name "$framework"/Resources/dev/lib/lib$framework_name.dylib || exit 1
}

copy_single_main_library()
{
    echo "Copying single main library..."

    cp $main_library "$framework"/$framework_name
    newid="$framework"/$framework_name
    install_name_tool -id "$newid" "$newid" || exit 1

    symlink_framework_library
}

resolve_dependencies()
{
    echo "Resolving dependencies ..."

    files_left=true
    nfiles=0

    while $files_left; do
	libs1=`find $framework_name.framework/Resources/lib -name "*.dylib" -o -name "*.so" 2>/dev/null`
	libs2=`find $framework_name.framework/Libraries -name "*.dylib" -o -name "*.so" 2>/dev/null`
	deplibs=`otool -L $libs1 $libs2 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep "$old_prefix"/lib | grep -v "$main_library" | sort | uniq`

	# Copy library and correct ID
	for j in $deplibs; do
	    j=`echo $j | sed -e "s@$old_prefix/lib@@"`
	    j=`echo $j | sed -e "s@^/@@"`

	    cp -f "$old_prefix"/lib/$j "$framework"/Libraries

	    libname=`echo $j | sed -e "s@[\.-0123456789].*@@"`
	    newid=`otool -L "$framework"/Libraries/$j 2>/dev/null | fgrep compatibility | grep $libname | cut -d\( -f1`
	    newid=`echo $newid | sed -e "s@$old_prefix/lib@$new_prefix@"`

	    install_name_tool -id "$newid" "$framework"/Libraries/"$j" || exit 1
	done

	nnfiles=`ls "$framework"/Libraries/*dylib 2>/dev/null| wc -l`;
	if [ $nnfiles = $nfiles ]; then
	    files_left=false
	else
	    nfiles=$nnfiles
	fi
    done
}

copy_pc_files()
{
    echo "Creating and copying pkg-config files ..."

    escaped_framework=`echo "$framework" | sed -e 's@\/@\\\/@g' -e 's@\.@\\\.@g'`

    if [ "x$2" != x ]; then
        requires='-e "s/\(^Requires:\).*/\1 $2/"'
    fi

    mkdir -p "$framework"/Resources/dev/lib/pkgconfig

    for pc in $1; do
    cat "$old_prefix"/lib/pkgconfig/$pc | sed \
        -e "s/\(^prefix=\).*/\1$escaped_framework\/Resources/" \
        -e "s/\(^Requires.private:\).*/\1/" \
        -e "s/\(^Libs:\).*/\1 -L$escaped_framework\/Resources\/dev\/lib -l$framework_name/" \
        -e "s/\(^Cflags:\).*/\1 -I$escaped_framework\/Headers/" > "$framework"/Resources/dev/lib/pkgconfig/$pc
    done
}

build_framework_library()
{
    echo "Building main $framework_name library..."

    make $framework_name >/dev/null || exit 1
    mv $framework_name "$framework"/$framework_name || exit 1

    symlink_framework_library
}

copy_headers()
{
    echo "Copying header files..."

    while(test "x$1" != x); do
        dir=$1
        shift 1

        if [ "x$1" == x ]; then
            echo "Wrong number of arguments, need pairs of from/to paths"
            exit 1
        fi

        tail=$1
        if [ x$tail == x. ]; then
            tail=
        fi

        shift 1

        cp -r "$old_prefix/$dir/$tail" "$framework/Headers/$tail"
    done
}

copy_dev_executables()
{
    echo "Copying executables..."

    mkdir -p "$framework"/Resources/dev/bin

    for i in $*; do
        full_path="$old_prefix"/bin/"$i"
        cp "$full_path" "$framework"/Resources/dev/bin

        if [ "x`file "$full_path" | grep Mach-O\ executable`" != x ]; then
            fixlibs=`otool -L "$full_path" 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep "$old_prefix"/lib`
	    for j in $fixlibs; do
                # Also change any references to the renamed gdk-pixbuf library.
	        new=`echo $j | sed -e s@$old_prefix/lib@$new_prefix@ -e s@libgdk_pixbuf-@libgdk-pixbuf-@`
	        install_name_tool -change "$j" "$new" "$framework"/Resources/dev/bin/"$i" || exit 1
	    done
        fi
    done
}

copy_aclocal_macros()
{
    echo "Copying aclocal macros..."

    dest="$framework"/Resources/dev/share/aclocal
    mkdir -p "$dest"

    for i in $*; do
        cp "$old_prefix"/share/aclocal/"$i" "$dest"
    done
}

