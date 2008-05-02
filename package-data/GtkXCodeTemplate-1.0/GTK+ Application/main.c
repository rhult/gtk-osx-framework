/*
 *  main.c
 *  ÇPROJECTNAMEÈ
 *
 *  Created by ÇFULLUSERNAMEÈ on ÇDATEÈ.
 *  Copyright ÇORGANIZATIONNAMEÈ ÇYEARÈ. All rights reserved.
 */

#include <gtk/gtk.h>

int
main (int argc, char **argv)
{
    GtkWidget *window;

    gtk_init (&argc, &argv);

    window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
    g_signal_connect (window, "destroy", G_CALLBACK (gtk_main_quit), NULL);
    gtk_widget_show_all (window);

    /* Add your widgets to the window here. */

    /* Run the main loop. */
    gtk_main ();

    return 0;
}
