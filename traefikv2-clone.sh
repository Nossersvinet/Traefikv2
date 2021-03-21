#!/bin/bash
function sudocheck () {
  if [[ $EUID -ne 0 ]]; then
    tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔️  You Must Execute as a SUDO USER (with sudo) or as ROOT!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 0
  fi
}

function clone() {
    sudo apt install git -yy
    sudo git clone --quiet https://github.com/doob187/Traefikv2 /opt/traefik
    sudo chown -cR 1000:1000 /opt/traefik/ 1>/dev/null 2>&1
    sudo chmod -cR 755 /opt/traefik >> /dev/null 1>/dev/null 2>&1
    sudo bash /opt/traefik/install.sh
}
sudocheck
clone
