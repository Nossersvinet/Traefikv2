#!/bin/bash
#
# Title:      LXC Bypass the mount :shared 
# OS Branch:  ubuntu,debian,rasbian
# Author(s):  mrdoob
# Coauthor:   DrAgOn141
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
LXC() {
  if [[ ! -x $(command -v rsync) ]];then $(command -v apt) install --reinstall rsync -yqq 1>/dev/null 2>&1;fi
  if [[ ! -f "/home/.lxcstart.sh" ]];then $(command -v rsync) /opt/traefik/installer/subinstall/lxcstart.sh /home/.lxcstart.sh -aq --info=progress2 -hv;fi
  if [[ -f "/home/.lxcstart.sh" ]];then 
     $(command -v chmod) a=rx,u+w /home/.lxcstart.sh
     $(command -v bash) /home/.lxcstart.sh
     $(command -v ansible-playbook) /opt/traefik/installer/subinstall/lxc.yml 1>/dev/null 2>&1
  fi
## set cron.d
  if [[ -f "/home/.lxcstart.sh" ]];then $(command -v ansible-playbook) /opt/traefik/installer/subinstall/lxc.yml 1>/dev/null 2>&1;fi
  if [[ ! -f "/etc/cron.d/lxcstart" ]];then
cat <<EOF > /etc/cron.d/lxcstart
SHELL=/bin/bash
@reboot root /bin/bash /home/.lxcstart.sh 1>/dev/null 2>&1
EOF
$(command -v chmod) a=rx,u+w /etc/cron.d/lxcstart
sleep 1
tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ❌ INFO
    Please be sure that you have add the following features 
    keyctl, nesting and fuse under LXC Options > Features, 
    this is only available when Unprivileged container=Yes

    The mount-docker takes round about 2 minutes to start 
    after the installation, please be patient
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
  read -erp "Confirm Info | PRESS [ENTER]" typed </dev/tty
fi
clear && exit
}
while true; do
 if [[ "$(systemd-detect-virt)" != "lxc" ]];then exit;fi
 LXC
done
