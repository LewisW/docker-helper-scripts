#!/bin/bash
set -e

CUR_DIR=dirname "$0"

if [ -f "$CUR_DIR/github-oauth.token" ]; then
        cp "$CUR_DIR/github-oauth.token" github-oauth.token
else
        
        if [ "$USER" = "" ]; then export USER="$1"; fi
        
        if [ "$USER" = "" ] && [ "$HOME" = "" ]; then
                echo '$HOME or $USER not set or passed in as argument'
                exit 1;
        fi
        
        if [ "$HOME" = "" ]; then export HOME="`getent passwd $USER | cut -f6 -d:`"; fi
        
        composer config -g github-oauth.github.com > github-oauth.token
fi;

# Reset the modified time so docker doesn't invalidate the cache between different servers
touch -t 200001010000.00 github-oauth.token

