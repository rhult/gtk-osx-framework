/**
 * Gtk.c  -- Framework initialization code.
 *
 * Copyright (C) 2007, 2008  Imendio AB
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BUNDLE_RESOURCES "../Frameworks/Gtk.framework/Resources"

#define RELATIVE_PANGO_RC_FILE		BUNDLE_RESOURCES"/etc/pango/pangorc"
#define RELATIVE_GTK_RC_FILE		BUNDLE_RESOURCES"/etc/gtk-2.0/gtkrc"
#define RELATIVE_GTK_IMMODULE_FILE	BUNDLE_RESOURCES"/etc/gtk-2.0/gtk.immodules"
#define RELATIVE_GDK_PIXBUF_MODULE_FILE	BUNDLE_RESOURCES"/etc/gtk-2.0/gdk-pixbuf.loaders"


static void set_rc_environment (const char *variable,
                                const char *executable_path,
                                const char *relative_file)
{
  char *rc_file;

  rc_file = malloc (strlen (executable_path) + strlen (relative_file));
  sprintf (rc_file, "%s%s", executable_path, relative_file);

  setenv (variable, rc_file, 1);

  free (rc_file);
}

__attribute__((constructor))
static void initializer (int argc, char **argv, char **envp)
{
  int i;
  char *executable_path;

  /* We figure out the executable path and then set up the PANGO_RC_FILE
   * environment variable.
   */
  executable_path = strdup (argv[0]);
  for (i = strlen (executable_path); i >= 0; i--)
    {
      if (executable_path[i] == '/')
	break;

      executable_path[i] = 0;
    }

  /* NOTE: leave the setting of the environment variables in this order,
   * otherwise things will fail in the Release builds for no obvious
   * reason.
   */
  set_rc_environment ("PANGO_RC_FILE", executable_path, RELATIVE_PANGO_RC_FILE);
  set_rc_environment ("GTK2_RC_FILES", executable_path, RELATIVE_GTK_RC_FILE);
  set_rc_environment ("GTK_IM_MODULE_FILE", executable_path, RELATIVE_GTK_IMMODULE_FILE);
  set_rc_environment ("GDK_PIXBUF_MODULE_FILE", executable_path, RELATIVE_GDK_PIXBUF_MODULE_FILE);

  setenv ("XDG_CONFIG_DIRS", BUNDLE_RESOURCES"/etc/xdg", 1);
  setenv ("XDG_DATA_DIRS", BUNDLE_RESOURCES"/share", 1);
  setenv ("GTK_DATA_PREFIX", BUNDLE_RESOURCES"/share", 1);
  setenv ("GTK_EXE_PREFIX", BUNDLE_RESOURCES, 1);
  setenv ("GTK_PATH", BUNDLE_RESOURCES, 1);

  free (executable_path);
}
