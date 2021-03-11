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
     if [[ "$IGPU" == "true" && $NGPU == "false" ]]; then
        echo "IGPU" && break
     elif [[ "$IGPU" == "true" && "$NGPU" == "true" ]]; then
        echo "IGPU & NVIDIA GPU" && break
     elif [[ "$IGPU" == "false" && "$NGPU" == "true" ]]; then
        echo "NVIDIA GPU" && break
     else
        echo "nothing found " && break
     fi
  else
     echo "lshw not found" && break
  fi
done

##IGPU
htest() {
HMOD=$(ls /etc/modprobe.d/ | grep -qE "hetzner" && echo true || echo false)
if [[ $HNOD != "false" ]]; then
   echo " blacklist-hetzner.conf found "
else
   echo " blacklist-hetzner.conf not found "
fi
}

igpuhetzner() {
ITE=$(cat /etc/modprobe.d/blacklist-hetzner.conf | grep -qE "#blacklist i915" && echo true || echo false)
IMO=$(cat /etc/default/grub | grep -qE 'GRUB_CMDLINE_LINUX_DEFAULT="nomodeset consoleblank=0"' && echo true || echo false)
GVIDEO=$(id $(whoami) | grep -qE 'video' && echo true || echo false)
DEVT=$(ls /dev/dri 1>/dev/null 2>&1 && echo true || echo false)
VIFO=$(command -v vainfo)

if [[ $ITE == "false" ]]; then
   sed -i "s/blacklist i915/#blacklist i915/g" /etc/modprobe.d/blacklist-hetzner.conf
fi
if [[ $IMO == "false" ]]; then
   sed -i "s/GRUB_CMDLINE_LINUX_DEFAUL/#GRUB_CMDLINE_LINUX_DEFAUL/g" /etc/modprobe.d/blacklist-hetzner.conf
fi
if [[ $IMO == "true" && $ITE == "true" ]]; then
   update-grub
fi
if [[ $GVIDEO != "true" ]]; then
   usermod -aG video $(whoami)
fi
if [[ $DEVT != "false" ]]; then
   chmod -R 750 /dev/dri
else
   echo ""
   printf "\033[0;31m You need to restart the server to get access to /dev/dri

   after restarting execute the install again\033[0m\n"
   echo ""
   read -p "Type confirm if you wish to continue: " input
   if [[ "$input" = "confirm" ]]; then
      reboot -n
   else
      igpuhetzner
   fi
fi
if [[ ! -f "$VIFO" ]]; then
   apt install vainfo -yqq
fi
}

##NVIDIA
nvidiarepo() {
CHK=$(cat /etc/apt/sources.list.d/nvidia-docker.list | grep -qE nvidia && echo true || echo false)
if [[ $CHK == "false" ]]; then
   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
     sudo apt-key add -
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
     sudo tee /etc/apt/sources.list.d/nvidia-docker.list
fi
}

nvidiainstall() {
CHKNV=$(command -v nvidia-smi)
if [[ ! -x "$CHKNV" ]]; then
   package_list="update upgrade nvidia-container-toolkit nvidia-container-runtime"
   for i in ${package_list}; do
       apt $i -yqq 1>/dev/null 2>&1
   done
fi
}

dockerpart() {
DCHK=$(cat /etc/docker/daemon.json | grep -qE 'nvidia' && echo true || echo false)
if [[ $DCHK == "false" ]]; then
sudo tee /etc/docker/daemon.json <<EOF
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
fi
}

dockerdreload() {
DREA=$(pidof dockerd && echo true || echo false)
if [[ $DREA == "true" ]]; then
   pkill -SIGHUP dockerd
fi
}

nvlastchk() {
DREA=$(pidof dockerd && echo true || echo false)
DCHK=$(cat /etc/docker/daemon.json | grep -qE 'nvidia' && echo true || echo false)
CHKNV=$(command -v nvidia-smi)

if [[ $DREA == "true" && $DCHK == "true" && $CHKNV == "true" ]]; then
   echo " nvidia-container-runtime is working"
else
   echo " nvidia-container-runtime is not working"
fi
}


