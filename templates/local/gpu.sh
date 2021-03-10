#!/bin/bash
#
# Title:      LSPCI || IGPU & NVIDIA GPU
# Author(s):  mrdoob
# URL:        https://sudobox.io/
# GNU:        General Public License v3.0
################################################################################
#FUNCTIONS

IGPU=$(lspci  -v -s  $(lspci | grep ' VGA ' | cut -d" " -f 1) | grep -E "i915" | tail -n1 && echo true || echo false)
NGPU=$(lspci  -v -s  $(lspci | grep ' VGA ' | cut -d" " -f 1) | grep -E "nvidia" | tail -n1 && echo true || echo false)
TLSPCI=$(command -v lspci && echo true || echo false)
while true; do
  if [[ $TLSPCI == "true" ]]; then
     echo "lspci found" && break
  else
     echo "lspci not found" && break
  fi
done 
