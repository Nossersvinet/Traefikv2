#!/bin/bash
#
# Title:      headinstaller based of matched OS 
# Author(s):  mrdoob
# URL:        https://sudobox.io/
# GNU:        General Public License v3.0
################################################
case $(. /etc/os-release && echo "$ID") in
    ubuntu)     type="ubuntu" ;;
    debian)     type="ubuntu" ;;
    rasbian)    type="ubuntu" ;;
    *)          type='' ;;
esac

if [ -e $type.sh ]; then
    bash ./installer/$type.sh
fi
