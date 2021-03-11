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


