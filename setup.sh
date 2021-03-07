#!/bin/bash
#
# Title:      Traefikv2 with Authelia over Cloudflare
# Author(s):  mrdoob
# URL:        https://sudobox.io/
# GNU:        General Public License v3.0
################################################################################
#FUNCTIONS
updatesystem() {
if [[ $EUID -ne 0 ]]; then
tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔  You Must Execute as a SUDO USER (with sudo) or as ROOT!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
exit 0
fi
while true; do
  package_list="update upgrade dist-upgrade autoremove autoclean"
  for i in ${package_list}; do
      apt $i -yqq 1>/dev/null 2>&1
  done
  if [[ ! -d "/mnt/downloads" && ! -d "/mnt/unionfs" ]]; then
     basefolder="/mnt"
     for i in ${basefolder}; do
         mkdir -p $i/{unionfs,downloads,incomplete,torrent,nzb} \
                  $i/{incomplete,downloads}/{nzb,torrent}/{movies,tv,tv4k,movies4k,movieshdr,tvhdr,remux} \
                  $i/{torrent,nzb}/watch
        find $i -exec chmod a=rx,u+w {} \;
        find $i -exec chown -hR 1000:1000 {} \;
     done
  fi
  if [[ ! -x "$(command -v docker)"  ]]; then
     package_list="update apt-transport-https ca-certificates curl wget gnupg-agent software-properties-common"
     for i in ${package_list}; do
         apt $i -yqq 1>/dev/null 2>&1
         sleep 1
     done
     curl --silent -fsSL https://raw.githubusercontent.com/docker/docker-install/master/install.sh | sudo bash > /dev/null 2>&1
     cp /opt/traefik/templates/local/daemon.j2 /etc/docker/daemon.json
  else
     cp /opt/traefik/templates/local/daemon.j2 /etc/docker/daemon.json
     curl --silent -fsSL https://raw.githubusercontent.com/docker/docker-install/master/install.sh | sudo bash > /dev/null 2>&1
  fi
  dockertest=$(systemctl is-active docker | grep "active" && echo true || echo false)
  if [[ $dockertest != "false" ]]; then systemctl reload-or-restart docker.service >/dev/null 2>1 && systemctl enable docker.service >/dev/null 2>&1; fi
  mntcheck=$(docker volume ls | grep unionfs | head -n1 && echo true || echo false)
  if [[ $mntcheck == "false" ]]; then bash /opt/traefik/templates/local/install.sh >/dev/null 2>&1 && docker volume create -d local-persist -o mountpoint=/mnt --name=unionfs >/dev/null 2>&1; fi
  networkcheck=$(docker network ls | grep "proxy" | tail -n 2 && echo true || echo false)
  if [[ $networkcheck == "false" ]]; then docker network create --driver=bridge proxy >/dev/null 2>1; fi
  if [[ ! -x "$(command -v docker-compose)" ]]; then
     COMPOSE_VERSION=$(curl --silent -fsSL https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
     sh -c "curl --silent -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
     sh -c "curl --silent -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose"
     if [[ ! -L "/usr/bin/docker-compose" ]]; then rm -f /usr/bin/docker-compose && ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose; fi
     chmod a=rx,u+w /usr/local/bin/docker-compose >/dev/null 2>&1
     chmod a=rx,u+w /usr/bin/docker-compose >/dev/null 2>&1
  fi
  if [[ ! -x "$(command -v fail2ban-client)" ]]; then apt install fail2ban -yqq >/dev/null 2>&1; fi
  LOCALMOD=$(cat /etc/fail2ban/jail.local && echo true || echo false)
  MOD=$(cat /etc/fail2ban/jail.local | grep [authelia] && echo true || echo false)
  if [[ $LOCALMOD == "false" ]]; then cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local; fi
  if [[ $MOD == "false" ]]; then
     echo "\

[authelia]
enabled = true
port = http,https,9091
filter = authelia
logpath = /opt/appdata/authelia/authelia.log
maxretry = 2
bantime = 90d
findtime = 7d
chain = DOCKER-USER">> /etc/fail2ban/jail.local
  ##traefik access.log banner
  sed -i "s#/var/log/traefik/access.log#/opt/appdata/traefik/traefik.log#g" /etc/fail2ban/jail.local
  sed -i "s#rotate 4#rotate 1#g" /etc/logrotate.conf
  sed -i "s#weekly#daily#g" /etc/logrotate.conf
  fi
  f2ban=$(systemctl is-active fail2ban | grep "active" && echo true || echo false)
  if [[ $f2ban != "false" ]]; then
     systemctl reload-or-restart fail2ban.service >/dev/null 2>&1
     systemctl enable fail2ban.service >/dev/null 2>&1
  fi
  if [[ ! -x "$(command -v rsync)" ]]; then apt install rsync -yqq >/dev/null 2>&1; fi
     rsync /opt/traefik/templates/ /opt/appdata/ -aq --info=progress2 -hv --exclude local
  if [[ -x "$(command -v rsync)" ]]; then  apt purge rsync -yqq  >/dev/null 2>&1; fi
  optfolder="/opt/appdata"
  for i in ${optfolder}; do
      mkdir -p $i/{authelia,traefik,compose,portainer} \
               $i/traefik/{rules,acme}
      find $i/{authelia,traefik,compose,portainer} -exec chown -hR 1000:1000 {} \;
  done
  touch ${optfolder}/traefik/acme/acme.json \
        ${optfolder}/traefik/traefik.log \
        ${optfolder}/authelia/authelia.log
  chmod 600 ${optfolder}/traefik/traefik.log \
            ${optfolder}/authelia/authelia.log \
            ${optfolder}/traefik/acme/acme.json
  break
done
interface
}
########## FUNCTIONS START
domain() {
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Treafikv2 Domain
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   read -ep "What root domain would you like to protect?: " DOMAIN

if [[ $DOMAIN == "" ]]; then
   echo "Domain cannot be empty"
   domain
else
   MODIFIED=$(cat /etc/hosts | grep $DOMAIN && echo true || echo false)
   if [[ $MODIFIED == "false" ]]; then
   echo "\
127.0.0.1  *.$DOMAIN
127.0.0.1  $DOMAIN" >> /etc/hosts
   fi
   if [[ $DOMAIN != "example.com" ]]; then
      if [[ $(uname) == "Darwin" ]]; then
         sed -i '' "s/example.com/$DOMAIN/g" /opt/appdata/authelia/configuration.yml
         sed -i '' "s/example.com/$DOMAIN/g" /opt/appdata/compose/docker-compose.yml
         sed -i '' "s/example.com/$DOMAIN/g" /opt/appdata/traefik/rules/middlewares.toml
      else
         sed -i "s/example.com/$DOMAIN/g" /opt/appdata/authelia/configuration.yml
         sed -i "s/example.com/$DOMAIN/g" /opt/appdata/compose/docker-compose.yml
         sed -i "s/example.com/$DOMAIN/g" /opt/appdata/traefik/rules/middlewares.toml
     fi
   fi
fi
interface
}
displayname() {
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Authelia Username
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   read -ep "Enter your display name for Authelia (eg. John Doe): " DISPLAYNAME

if [[ $DISPLAYNAME != "" ]]; then
   if [[ $(uname) == "Darwin" ]]; then
      sed -i '' "s/<DISPLAYNAME>/$DISPLAYNAME/g" /opt/appdata/authelia/users_database.yml
      sed -i '' "s/<USERNAME>/$DISPLAYNAME/g" /opt/appdata/authelia/users_database.yml
   else
      sed -i "s/<DISPLAYNAME>/$DISPLAYNAME/g" /opt/appdata/authelia/users_database.yml
      sed -i "s/<USERNAME>/$DISPLAYNAME/g" /opt/appdata/authelia/users_database.yml
   fi
else
  echo "Display name cannot be empty"
  displayname
fi
interface
}

password() {
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Authelia Password
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   read -esp "Enter a password for $USERNAME: " PASSWORD

if [[ $PASSWORD != "" ]]; then
   docker pull authelia/authelia -q > /dev/null
   PASSWORD=$(docker run authelia/authelia authelia hash-password $PASSWORD -i 2 -k 32 -m 128 -p 8 -l 32 | sed 's/Password hash: //g')
   JWTTOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
   SECTOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
   if [[ $(uname) == "Darwin" ]]; then
      sed -i '' "s/<PASSWORD>/$(echo $PASSWORD | sed -e 's/[\/&]/\\&/g')/g" /opt/appdata/authelia/users_database.yml
      sed -i '' "s/JWTTOKENID/$(echo $JWTTOKEN | sed -e 's/[\/&]/\\&/g')/g" /opt/appdata/authelia/configuration.yml
      sed -i '' "s/SECTOKEN/unsecure_session_secret  | sed -e 's/[\/&]/\\&/g')/g" /opt/appdata/authelia/configuration.yml
   else
      sed -i "s/<PASSWORD>/$(echo $PASSWORD | sed -e 's/[\/&]/\\&/g')/g" /opt/appdata/authelia/users_database.yml
      sed -i "s/JWTTOKENID/$(echo $JWTTOKEN | sed -e 's/[\/&]/\\&/g')/g" /opt/appdata/authelia/configuration.yml
      sed -i "s/SECTOKEN/unsecure_session_secret | sed -e 's/[\/&]/\\&/g')/g" /opt/appdata/authelia/configuration.yml
   fi
else
  echo "Password cannot be empty"
  password
fi
interface
}
cfemail() {
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Cloudflare Email-Address
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   read -ep "Whats your CloudFlare-Email-Address : " EMAIL

if [[ $EMAIL != "" ]]; then
   if [[ $(uname) == "Darwin" ]]; then
      sed -i '' "s/example-CF-EMAIL/$EMAIL/g" /opt/appdata/authelia/configuration.yml
      sed -i '' "s/example-CF-EMAIL/$EMAIL/g" /opt/appdata/authelia/users_database.yml
      sed -i '' "s/example-CF-EMAIL/$EMAIL/g" /opt/appdata/compose/docker-compose.yml
   else
      sed -i "s/example-CF-EMAIL/$EMAIL/g" /opt/appdata/authelia/configuration.yml
      sed -i "s/example-CF-EMAIL/$EMAIL/g" /opt/appdata/authelia/users_database.yml
      sed -i "s/example-CF-EMAIL/$EMAIL/g" /opt/appdata/compose/docker-compose.yml
   fi
else
  echo "CloudFlare-Email-Address cannot be empty"
  cfemail
fi
interface
}
cfkey() {
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Cloudflare Global-Key
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   read -ep "Whats your CloudFlare-Global-Key: " CFGLOBAL

if [[ $CFGLOBAL != "" ]]; then
   if [[ $(uname) == "Darwin" ]]; then
      sed -i '' "s/example-CF-API-KEY/$CFGLOBAL/g" /opt/appdata/authelia/configuration.yml
      sed -i '' "s/example-CF-API-KEY/$CFGLOBAL/g" /opt/appdata/compose/docker-compose.yml
   else
      sed -i "s/example-CF-API-KEY/$CFGLOBAL/g" /opt/appdata/authelia/configuration.yml
      sed -i "s/example-CF-API-KEY/$CFGLOBAL/g" /opt/appdata/compose/docker-compose.yml
   fi
else
  echo "CloudFlare-Global-Key cannot be empty"
  cfkey
fi
interface
}

jounanctlpatch() {
CTPATCH=$(cat /etc/systemd/journald.conf | grep "#PATCH" && echo true || echo false)
  if [[ $CTPATCH == "false" ]]; then
     journalctl --flush 1>/dev/null 2>&1
     journalctl --rotate 1>/dev/null 2>&1
     journalctl --vacuum-time=1s 1>/dev/null 2>&1
     find /var/log -name "*.gz" -delete 1>/dev/null 2>&1
   echo "\

#PATCH
Storage=volatile
Compress=yes
SystemMaxUse=100M
SystemMaxFileSize=10M
SystemMaxFiles=10
MaxLevelStore=crit" >>/etc/systemd/journald.conf
fi
}
serverip() {
SERVERIP=$(ip addr show |grep 'inet '|grep -v 127.0.0.1 |awk '{print $2}'| cut -d/ -f1 | head -n1)
if [[ $SERVERIP != "" ]]; then
   if [[ $(uname) == "Darwin" ]]; then
      sed -i '' "s/SERVERIP_ID/$SERVERIP/g" /opt/appdata/authelia/configuration.yml
   else
      sed -i "s/SERVERIP_ID/$SERVERIP/g" /opt/appdata/authelia/configuration.yml
   fi
else
  echo "Server-IP cannot be empty"
  serverip
fi
}

ccontainer() {
container=$(docker ps -aq --format '{{.Names}}' | sed '/^$/d' | grep -E 'trae|auth|error-pag')
if [[ $container != "" ]]; then
   docker stop $container 1>/dev/null 2>&1
   docker rm $container 1>/dev/null 2>&1
   docker image prune -af 1>/dev/null 2>&1
else
   docker image prune -af 1>/dev/null 2>&1
fi
}

deploynow() {
jounanctlpatch
serverip
ccontainer
cd /opt/appdata/compose && docker-compose up -d 1>/dev/null 2>&1 && sleep 5
while true; do
  container="authelia traefik traefik-error-pages"
  for i in ${container}; do
      if [[ "$(docker container inspect -f '{{.State.Status}}' $i )" == "running" ]]; then echo " --> Container $i is up and running <--" && sleep 2; fi
  done
break
done
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Treafikv2 with Authelia
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

       Traefikv2 with Authelia is deployed

   Please Wait some minutes Authelia and Treafik 
     need some minutes to start all services

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
sleep 30
while true; do
  container="authelia traefik traefik-error-pages"
  for i in ${container}; do
      if [[ "$(docker container inspect -f '{{.State.Status}}' $i )" != "running" ]]; then deploynow && sleep 2; fi
  done
break
done
interface
}
######################################################
interface() {
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Treafikv2 with Authelia over Cloudflare
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1] Domain                            [ $DOMAIN ]
[2] Authelia Username                 [ $DISPLAYNAME ]
[3] Authelia Password                 [ $PASSWORD ]
[4] CloudFlare-Email-Address          [ $EMAIL ]
[5] CloudFlare-Global-Key             [ $CFGLOBAL ]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[D] Deploy Traefikv2 with Authelia

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Z] - Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
  read -p '↘️  Type Number | Press [ENTER]: ' typed </dev/tty
  case $typed in
  1) domain && interface ;;
  2) displayname && interface ;;
  3) password && interface ;;
  4) cfemail && interface ;;
  5) cfkey && interface ;;
  d) deploynow && interface ;;
  D) deploynow && interface ;;
  z) exit 0 ;;
  Z) exit 0 ;;
  *) interface ;;
  esac
}
# FUNCTIONS END ##############################################################
updatesystem
