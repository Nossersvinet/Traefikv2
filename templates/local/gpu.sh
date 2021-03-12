#!/bin/bash
#
# Title:      LSPCI || IGPU & NVIDIA GPU
# Author(s):  mrdoob
# URL:        https://sudobox.io/
# GNU:        General Public License v3.0
################################################################################
#FUNCTIONS

IGPU=$(lshw -C video | grep -qE 'i915' && echo true || echo false)
NGPU=$(lshw -C video | grep -qE 'nvidia' && echo true || echo false)
TLSPCI=$(command -v lshw)

while true; do
  if [[ -x "$TLSPCI" ]]; then
     echo "lshw found"
     if [[ "$IGPU" == "true" && $NGPU == "false" ]]; then
        igpuhetzner && break
     elif [[ "$IGPU" == "true" && "$NGPU" == "true" ]]; then
        nvidiagpu && break
     elif [[ "$IGPU" == "false" && "$NGPU" == "true" ]]; then
        nvidiagpu && break
     else
        echo "nothing found " && break
     fi
  else
     echo "lshw not found" && break
  fi
done


##IGPU
igpuhetzner() {
HMOD=$(ls /etc/modprobe.d/ | grep -qE "hetzner" && echo true || echo false)
ITE=$(cat /etc/modprobe.d/blacklist-hetzner.conf | grep -qE "#blacklist i915" && echo true || echo false)
IMO=$(cat /etc/default/grub | grep -qE 'GRUB_CMDLINE_LINUX_DEFAULT="nomodeset consoleblank=0"' && echo true || echo false)
GVIDEO=$(id $(whoami) | grep -qE 'video' && echo true || echo false)
DEVT=$(ls /dev/dri 1>/dev/null 2>&1 && echo true || echo false)
VIFO=$(command -v vainfo)

if [[ $HNOD != "false" ]]; then
   echo " blacklist-hetzner.conf found "
else
   echo " blacklist-hetzner.conf not found " && exit  0
fi
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
nvidiagpu() {
DREA=$(pidof dockerd && echo true || echo false)
CHKNV=$(ls /usr/bin/nvidia-smi 1>/dev/null 2>&1 && echo true || echo false)
DCHK=$(cat /etc/docker/daemon.json | grep -qE 'nvidia' && echo true || echo false)
CHK=$(cat /etc/apt/sources.list.d/nvidia-docker.list | grep -qE nvidia && echo true || echo false)
DEVT=$(ls /dev/dri 1>/dev/null 2>&1 && echo true || echo false)

if [[ $CHK == "false" ]]; then
   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
     sudo apt-key add -
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
     sudo tee /etc/apt/sources.list.d/nvidia-docker.list
fi
if [[ $CHKNV != "true" ]]; then
   package_list="update upgrade nvidia-container-toolkit nvidia-container-runtime"
   for i in ${package_list}; do
       apt $i -yqq 1>/dev/null 2>&1
   done
fi
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
if [[ $DREA == "true" ]]; then
   pkill -SIGHUP dockerd
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
      nvidiagpu
   fi
fi
if [[ $DREA == "true" && $DCHK == "true" && $CHKNV == "true" && $DEVT != "false" ]]; then
   echo " nvidia-container-runtime is working"
else
   echo " nvidia-container-runtime is not working"
fi
}


