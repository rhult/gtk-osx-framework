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
    gtk_window_set_default_size (GTK_WINDOW (window), 300, 200);
    gtk_window_set_position (GTK_WINDOW (window), GTK_WIN_POS_CENTER);

    /* Quit when the window is closed. */
    g_signal_connect (window, "destroy",
                      G_CALLBACK (gtk_main_quit),
                      NULL);

    /* Add your widgets to the window here. */

    gtk_widget_show_all (window);

    /* Run the main loop. */
    gtk_main ();

    return 0;
}
