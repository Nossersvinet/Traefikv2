#!/bin/bash
#
# Title:      LXC Bypass the mount :shared 
# OS Branch:  ubuntu,debian,rasbian
# Author(s):  mrdoob
# Coauthor:   DrAgOn141
# URL:        https://sudobox.io/
# GNU:        General Public License v3.0
################################################################################
# shellcheck disable=SC2003
# shellcheck disable=SC2006
# shellcheck disable=SC2207
# shellcheck disable=SC2012
# shellcheck disable=SC2086
# shellcheck disable=SC2196
# shellcheck disable=SC2046
#FUNCTIONS

## note
## here the actions
LXC() {
  if [[ ! -x $(command -v rsync) ]];then $(command -v apt) install --reinstall rsync -yqq 1>/dev/null 2>&1;fi
     $(command -v rsync) /opt/traefik/installer/.subinstall/lxcstart.sh /root/lxcstart.sh -aq --info=progress2 -hv
     $(command -v chmod) a+x /root/lxcstart.sh
## set crontab



if [[ "$(systemd-detect-virt)" == "lxc" ]];then
   LXC
else
   exit
fi
