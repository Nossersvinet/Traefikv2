#!/bin/bash
#
# Title:      LSPCI || IGPU & NVIDIA GPU
# Author(s):  mrdoob
# URL:        https://sudobox.io/
# GNU:        General Public License v3.0
################################################################################
#FUNCTIONS

IGPU=$(lspci -v -s $(lspci | grep ' VGA ' | cut -d" " -f 1) | grep -E 'i915' | awk '{print $5}')
NGPU=$(lspci -v -s $(lspci | grep ' VGA ' | cut -d" " -f 1) | grep -E 'nvidia' | awk '{print $5}')
TLSPCI=$(command -v lspci)

while true; do
  if [[ ! -x "$TLSPCI" ]]; then
     echo "lspci not found" && break
  else
     echo "lspci found"
  fi
  if [[ $IGPU == "i915" && $NGPU == "" ]]; then
     echo "IGPU" && break
  fi
  if [[ $IGPU == "i915" && $NGPU == "nvidia" ]]; then
     echo "IGPU && NVIDIA GPU" && break
  fi
  if [[ $IGPU == "" && $NGPU == "nvidia" ]]; then
     echo "NVIDIA GPU" && break
  fi

done 
