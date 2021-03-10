#!/bin/bash
#
# Title:      LSPCI || IGPU & NVIDIA GPU
# Author(s):  mrdoob
# URL:        https://sudobox.io/
# GNU:        General Public License v3.0
################################################################################
#FUNCTIONS

IGPU=$(lshw -C display | grep -q 'i915' && echo true || echo false && echo true || echo false)
NGPU=$(lshw -C display | grep -q 'nvidia' && echo true || echo false && echo true || false)
TLSPCI=$(command -v lshw)

while true; do
  if [[ -x "$TLSPCI" ]]; then
     echo "lshw found"
     if [[ $IGPU == "true" && $NGPU == "false" ]]; then
        echo "IGPU" && break
     elif [[ $IGPU == "true" && $NGPU == "true" ]]; then
        echo "IGPU & NVIDIA GPU" && break
     elif [[ $IGPU == "false" && $NGPU == "true" ]]; then
        echo "NVIDIA GPU" && break
     else
        echo "nothing found " && break
     fi
  else
     echo "lshw not found" && break
  fi
done
