#!/usr/bin/env sh

# We need this to be able to install into the home directory, which is
# the only place where Xcode templates can be installed consistantly
# across versions.

developer="$HOME/Library/Application Support/Developer"
templates="$developer/Shared/Xcode/Project Templates"

mkdir -p "$templates"
chown -R $USER "$developer"
ln -shf "$templates" /var/tmp/gtktemplate
