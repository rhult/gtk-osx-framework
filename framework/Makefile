#
# Copyright (C) 2007, 2008 Imendio AB
#

CFLAGS = -Wall -gstabs+3 -flat_namespace -mmacosx-version-min=10.4 -isysroot /Developer/SDKs/MacOSX10.4u.sdk

GLIB_INCLUDES = -I$(shell pwd)/GLib.framework/Headers/ -L$(shell pwd)/GLib.framework/Libraries/
GLIB_NAME = -install_name $(shell pwd)/GLib.framework/GLib

CAIRO_INCLUDES = -I$(shell pwd)/Cairo.framework/Headers/ -L$(shell pwd)/Cairo.framework/Libraries/
CAIRO_NAME = -install_name $(shell pwd)/Cairo.framework/Cairo

GTK_INCLUDES = -I$(shell pwd)/Gtk.framework/Headers/ -L$(shell pwd)/Gtk.framework/Libraries/
GTK_LDFLAGS = -F$(shell pwd)
GTK_NAME = -install_name $(shell pwd)/Gtk.framework/Gtk

all: GLib Cairo Gtk

GLib:
	gcc $(CFLAGS) -dynamiclib -o $@ $@.c $(GLIB_NAME) $(GLIB_INCLUDES) $(GLIB_SUBLIBS) $(GLIB_LIBS)

Cairo:
	gcc $(CFLAGS) -dynamiclib -o $@ $@.c $(CAIRO_NAME) $(CAIRO_INCLUDES) $(CAIRO_SUBLIBS) $(CAIRO_LIBS)

Gtk: Gtk.c
	gcc $(CFLAGS) -dynamiclib -o $@ $@.c $(GTK_NAME) $(GTK_INCLUDES) $(GTK_SUBLIBS) $(GTK_LIBS)

GLIB_LIBS = \
	-lintl.8			\
	-liconv				\
	-lglib-2.0.0			\
	-lgobject-2.0.0			\
	-lgmodule-2.0.0			\
	-lgthread-2.0.0

GLIB_SUBLIBS = \
	-sub_library libintl		\
	-sub_library libglib-2		\
	-sub_library libgobject-2	\
	-sub_library libgmodule-2	\
	-sub_library libgthread-2

CAIRO_LIBS = \
	-lz				\
	-lpng12.0			\
	-lpixman-1.0			\
	-lcairo.2

CAIRO_SUBLIBS = \
	-sub_library libcairo		\
	-sub_library libpixman-1

GTK_LIBS = \
	$(GTK_LDFLAGS)			\
	-lpng12.0			\
	-lpango-1.0.0			\
	-lpangocairo-1.0.0		\
	-latk-1.0.0			\
	-lgdk-pixbuf-2.0.0		\
	-lgdk-quartz-2.0.0		\
	-lgtk-quartz-2.0.0		\
	-ligemacintegration.0		\
	-framework Carbon		\
	-framework GLib			\
	-framework Cairo

GTK_SUBLIBS = \
	-sub_library libpango-1		\
	-sub_library libpangocairo-1	\
	-sub_library libatk-1		\
	-sub_library libgdk-pixbuf-2	\
	-sub_library libgdk-quartz-2	\
	-sub_library libgtk-quartz-2	\
	-sub_library libigemacintegration

clean:
	rm -rf Gtk GLib Cairo Loudmouth
