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
     $(command -v rsync) /opt/traefik/installer/.subinstall/lxcstart.sh /home/.lxcstart.sh -aq --info=progress2 -hv
     $(command -v chmod) a+x /home/.lxcstart.sh
## set crontab
cat <<EOF > /etc/cron.d/lxcstart
@reboot root /home/.lxcstart.sh 1>/dev/null 2>&1
EOF
sleep 5
tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ❌ INFO
    please add follow features to your LXC Container
    keyctl, nesting and fuse
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
  read -erp "Confirm Info | PRESS [ENTER]" typed </dev/tty


clear && exit
}


if [[ "$(systemd-detect-virt)" == "lxc" ]];then
   LXC
else
   exit
fi
