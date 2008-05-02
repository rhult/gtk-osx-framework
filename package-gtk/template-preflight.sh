#!/usr/bin/env sh

dir="$HOME/Library/Application Support/Developer/Shared/Xcode/Project Templates"

mkdir -p "$dir"
chown $USER "$dir"
ln -shf "$dir" /var/tmp/gtktemplate
