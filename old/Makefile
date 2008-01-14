#
# Copyright (C) 2007  Imendio AB
#

INCLUDE = -I$(HOME)/src/gtk-framework/Gtk.framework/Headers/ -L$(HOME)/src/gtk-framework/Gtk.framework/Libraries/
NAME = -install_name $(HOME)/src/gtk-framework/Gtk.framework/Gtk

LIBS =	\
	   -lz			\
	   -lintl		\
	   -liconv		\
	   -lpng12		\
	   -lcairo		\
	   -lglib-2.0		\
	   -lgobject-2.0	\
	   -lgmodule-2.0	\
	   -lpango-1.0		\
	   -lpangocairo-1.0	\
	   -latk-1.0		\
	   -lgdk_pixbuf-2.0	\
	   -lgdk-quartz-2.0	\
	   -lgtk-quartz-2.0

SUBLIBS	= \
	  -sub_library libintl		\
	  -sub_library libpng12		\
	  -sub_library libcairo		\
	  -sub_library libglib-2	\
	  -sub_library libgobject-2	\
	  -sub_library libgmodule-2	\
	  -sub_library libpango-1	\
	  -sub_library libpangocairo-1	\
	  -sub_library libatk-1		\
	  -sub_library libgdk		\
	  -sub_library libgdk-quartz-2	\
	  -sub_library libgtk-quartz-2

all:		Gtk

Gtk:		Gtk.c
		gcc -Wall -dynamiclib -o Gtk -g Gtk.c $(NAME) $(INCLUDE) $(SUBLIBS) $(LIBS)
