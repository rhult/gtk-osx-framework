GTK+ OSX SDK
============

Copyright (C) 2007, 2008  Imendio AB


The files that are found in this repository can be used to create a proper
GTK+ SDK for Mac OS X.  This SDK is built after common Mac standards and
integrates with the system and the XCode IDE as much as possible.  Building
and installing your own SDK using these files is not recommended for
end-users, download one of the installable PKG files instead.

Contents of the repository and usage notes follow below.


Known issues
------------

* This is all still very beta ;)

* The binaries are not universal, but Intel only!  Building proper
  universal binaries of the GTK+ binaries is hard and not fully
  automated yet.  We hope to provide proper universal binaries at
  some later point.

* Translations and theme data are not yet included.

* The binaries do still contain debugging information.  This debugging
  information is only of use to get proper stack traces at this moment.
  At some later point we might decide to ship with stripped binaries.

* A script/application to transform the application created with XCode
  to a stand-alone binary (with the framework included inside) has not
  yet been included.  We are still investigating what the best way is
  to include this.  At some later point this will appear as a small
  application or as a separate target in XCode.

* We are not shipping vanilla GTK+ binaries.  This is due to a missing
  Pango feature (which will be merged upstream) and to workaround
  10.4 compatibility issues on Mac OS X 10.5.


Contents
--------

* GTK+ Quartz Application

	This is an XCode Project Template.  This directory should be copied
	in full to:

/Library/Application Support/Apple/Developer Tools/Project Templates/Application/

	XCode will automatically pick up the new template.  When creating
	a new project, look for the "GTK+ Quartz Application" entry.
	When creating a GTK+ application this way, the build settings and
	configuration will be taken care of automatically.

	Note: This requires the Gtk.framework to be installed under
	/Library/Frameworks !

* framework-scripts

	This directory contains the various files and scripts to create
	a working Gtk.framework:

	# Gtk.c, Makefile

		Code and makefile for the framework initialization
		machinery.

	# create-framework.sh

		Given a prefix where GTK+ has been compiled into (say
		/opt), this script will create an "intermediate"
		Gtk.framework in the current working directory.

	# prepare-for-system.sh

		Modifies a given Gtk.framework so that it can be
		installed in /Library/Frameworks

	# make-standalone.sh

		Little script to convert an application bundle depending
		on the framework in /Library/Frameworks to be stand-alone.
		(See also the notes below).

	# convert-to-app-bundle.sh

		Copies Gtk.framework from /Library/Frameworks to the
		current working directory and makes it suitable for
		bundling it inside application bundles.

* patches

	Patches against GTK+ and Pango that are required to get
	things working.  We will try to get rid of this specific
	patching if possible.

* old

	Old framework creation scripts that did a little more
	sophisticated dependency resolution and symlink creation.  Only
	here for reference.


Steps to create a working SDK
-----------------------------

1. Build GTK+ for OSX from SVN using jhbuild.
2. Create the framework using create-framework.sh.
3. Convert the framework using prepare-for-system.sh.  After that, copy
   Gtk.framework in full to /Library/Frameworks.
4. Copy the Xcode project template to the correct directory.
5. Launch XCode and start hacking.


Creating stand-alone applications
---------------------------------

Applications that have been built using the "Release" build configuration
in XCode can be converted to be stand-alone as follows:

1. Copy the application bundle from the "build/Release" directory in your
   project directory.
2. Run make-standalone.sh with your application bundle as argument.
   The script will copy the Gtk.framework into your application bundle
   and make the necessary modifications.
3. Ship it!
