GTK+ 2.14

This package contains three frameworks needed for developing GTK+ applications natively on Mac OS X: GLib, Cairo and GTK+.

The frameworks contain the following components:

GLib:

  glib 2.18.1
  gettext 0.16
  intltool 0.40.3

Cairo:

  cairo 1.7.4
  pixman 0.12
  libpng 1.2.29

GTK+:

  gtk+ 2.14.2
  pango 1.21.5
  atk 1.23.5
  ige-mac-integration 0.8.2
  gnome-icon-theme 2.23.90
  hicolor-icon-theme 0.10
  gtk-engines 2.15.4 (only Clearlooks)
  libpng 1.2.29
  tiff 3.8.2
  jpeg 6b


The frameworks are developer versions with debugging symbols and the necessary setup for building both Xcode projects and "autotools" projects against them. Note that Xcode 2.5 or later is needed. See:

  http://developer.imendio.com/projects/gtk-osx for more information.

Note that this package is still in a beta phase, in particular, the exact selection of libraries and tools included in the frameworks might change in the next version. Therefore it is best not to distribute the frameworks as standalone frameworks, but only included inside application bundles for now. Tools to produce standalone app bundles using those frameworks will be provided later.
