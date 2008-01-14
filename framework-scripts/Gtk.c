/**
 * Gtk.c  -- Framework initialization code.
 *
 * Copyright (C) 2007, 2008  Imendio AB
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define RELATIVE_RC_FILE "../Frameworks/Gtk.framework/Resources/etc/pango/pangorc"

__attribute__((constructor))
static void initializer (int argc, char **argv, char **envp)
{
  int i;
  char *executable_path;
  char *pango_rc;

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

  pango_rc = malloc (strlen (executable_path) + strlen (RELATIVE_RC_FILE));
  sprintf (pango_rc, "%s%s", executable_path, RELATIVE_RC_FILE);

  setenv ("PANGO_RC_FILE", pango_rc, 1);

  free (pango_rc);
  free (executable_path);
}
