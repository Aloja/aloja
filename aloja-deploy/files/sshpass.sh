#!/bin/bash
# 
# script that passes password from stdin to ssh. 
# 
# Copyright (C) 2010 André Frimberger <andre OBVIOUS_SIGN frimberger.de>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or 
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# see http://andre.frimberger.de/index.php/linux/reading-ssh-password-from-stdin-the-openssh-5-6p1-compatible-way/

 
if [ -n "$SSH_ASKPASS_TMPFILE" ]; then
    cat "$SSH_ASKPASS_TMPFILE"
    exit 0
elif [ $# -lt 1 ]; then
    echo "Usage: echo password | $0 <ssh command line options>" >&2
    exit 1
fi
 
sighandler() {
    rm "$TMP_PWD"
}
 
TMP_PWD=$(mktemp)
chmod 600 "$TMP_PWD"
trap 'sighandler' SIGHUP SIGINT SIGQUIT SIGABRT SIGKILL SIGALRM SIGTERM
 
export SSH_ASKPASS=$0
export SSH_ASKPASS_TMPFILE=$TMP_PWD
 
[ "$DISPLAY" ] || export DISPLAY=dummydisplay:0
password=$1
shift
echo "$password" >> "$TMP_PWD"
 
# use setsid to detach from tty
exec setsid "$@"
 
rm "$TMP_PWD"
