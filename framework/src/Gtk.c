/*
 * Gtk.c - Framework initialization code.
 *
 * Copyright (C) 2007, 2008 Imendio AB
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <mach-o/dyld.h>
#include <Carbon/Carbon.h>
#include <CoreFoundation/CoreFoundation.h>

/* Relative location of the framework in an application bundle. */
#define FRAMEWORK_OFFSET                        "./Contents/Frameworks/Gtk.framework"

#define RELATIVE_PANGO_RC_FILE			"/Resources/etc/pango/pangorc"
#define RELATIVE_GTK_RC_FILE			"/Resources/etc/gtk-2.0/gtkrc"
#define RELATIVE_GTK_IMMODULE_FILE		"/Resources/etc/gtk-2.0/gtk.immodules"
#define RELATIVE_GDK_PIXBUF_MODULE_FILE		"/Resources/etc/gtk-2.0/gdk-pixbuf.loaders"

/* Define those so we can build this outside of jhbuild. */
int  _ige_mac_menu_is_quit_menu_item_handled (void);
int  _ige_mac_dock_is_quit_menu_item_handled (void);
void gtk_main_quit                           (void);

/* Make the bundle prefix available to the outside. */
static char *bundle_prefix = NULL;

const char *
_gtk_quartz_framework_get_bundle_prefix (void)
{
  return bundle_prefix;
}

static void
set_rc_environment (const char *variable,
                    const char *bundle_prefix,
                    const char *relative_path)
{
  char *value;

  value = malloc (strlen (bundle_prefix) + strlen (relative_path) + 1);
  strcpy (value, bundle_prefix);
  strcpy (value + strlen (bundle_prefix), relative_path);

#ifdef ENABLE_DEBUG
  printf ("%s = %s\n", variable, value);
#endif

  if (setenv (variable, value, 1) < 0)
    perror ("Couldn't set environment variable");

  free (value);
}

static int
is_running_from_app_bundle (void)
{
  int i;

  /* Use dyld magic to figure out whether we are running against the
   * system's Gtk.framework or a Gtk.framework bundled in an application
   * bundle.
   */
  for (i = 0; i < _dyld_image_count (); i++)
    {
      const char *name = _dyld_get_image_name (i);

      if (strstr (name, "/Gtk.framework/"))
        {
          if (!strncmp (name, "/Library/", 9))
            return 0;
          else
            return 1;
        }
    }

  /* Shouldn't be reached... */
  return 0;
}

static OSErr
handle_quit_cb (const AppleEvent *inAppleEvent,
                AppleEvent       *outAppleEvent,
                long              inHandlerRefcon)
{
  /* We only quit if there is no menu or dock setup. */
  if (!_ige_mac_menu_is_quit_menu_item_handled () &&
      !_ige_mac_dock_is_quit_menu_item_handled ())
    {
      gtk_main_quit ();
    }

  return noErr;
}

/* Note: using an initializer does not currently work when building against
 * 10.4 SDK and running on 10.5, so we use a function called from inside
 * GTK+ instead.
 */
/*__attribute__((constructor)) */ static void
initializer (int argc, char **argv, char **envp)
{
  static int initialized = 0;

  if (initialized)
    return;
  initialized = 1;

  /* Figure out correct bundle prefix. */
  if (!is_running_from_app_bundle ())
    {
      bundle_prefix = strdup ("/Library/Frameworks/Gtk.framework");
    }
  else
    {
      char executable_path[PATH_MAX];
      CFURLRef url;

      url = CFBundleCopyBundleURL (CFBundleGetMainBundle ());
      if (!CFURLGetFileSystemRepresentation (url, true, (UInt8 *)executable_path, PATH_MAX))
        assert(false);
      CFRelease (url);

      bundle_prefix = malloc (strlen (executable_path) + 1 + strlen (FRAMEWORK_OFFSET) + 1);
      strcpy (bundle_prefix, executable_path);
      strcpy (bundle_prefix + strlen (executable_path), "/");
      strcpy (bundle_prefix + strlen (executable_path) + 1, FRAMEWORK_OFFSET);

      free (executable_path);
    }

  /* NOTE: leave the setting of the environment variables in this order,
   * otherwise things will fail in the Release builds for no obvious reason.
   */
  set_rc_environment ("PANGO_RC_FILE", bundle_prefix, RELATIVE_PANGO_RC_FILE);
  set_rc_environment ("GTK2_RC_FILES", bundle_prefix, RELATIVE_GTK_RC_FILE);
  set_rc_environment ("GTK_IM_MODULE_FILE", bundle_prefix, RELATIVE_GTK_IMMODULE_FILE);
  set_rc_environment ("GDK_PIXBUF_MODULE_FILE", bundle_prefix, RELATIVE_GDK_PIXBUF_MODULE_FILE);

  set_rc_environment ("XDG_CONFIG_DIRS", bundle_prefix, "/Resources/etc/xdg");
  set_rc_environment ("XDG_DATA_DIRS", bundle_prefix, "/Resources/share");
  set_rc_environment ("GTK_DATA_PREFIX", bundle_prefix, "/Resources");
  set_rc_environment ("GTK_EXE_PREFIX", bundle_prefix, "/Resources");
  set_rc_environment ("GTK_PATH", bundle_prefix, "/Resources");

  /* Handle quit menu item so that apps can be quit of of the box. */
  AEInstallEventHandler (kCoreEventClass, kAEQuitApplication,
                         handle_quit_cb,
                         0, true);
}

void
_gtk_quartz_framework_init (void)
{
#ifdef ENABLE_DEBUG
  printf ("Initializing GTK+ framework\n");
#endif

  initializer (0, NULL, NULL);
}
