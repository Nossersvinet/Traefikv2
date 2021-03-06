#!/bin/bash
#
# Title:      Traefikv2 with Authelia over Cloudflare
# Author(s):  mrdoob
# URL:        https://sudobox.io/
# GNU:        General Public License v3.0
################################################################################
#FUNCTIONS
updatesystem() {
while true; do
  if [[ ! -d "/mnt/downloads" && ! -d "/mnt/unionfs" ]]; then
     basefolder="/mnt"
     for i in ${basefolder}; do
         mkdir -p $i/{unionfs,downloads,incomplete,torrent,nzb} \
                  $i/{incomplete,downloads}/torrent/{movies,tv,tv4k,movies4k} \
                  $i/{incomplete,downloads}/nzb/{movies,tv,tv4k,movies4k} \
                  $i/{torrent,nzb}/watch
        find $i -exec chmod a=rx,u+w {} \;
        find $i -exec chown -hR 1000:1000 {} \;
    done
  fi
  if [[ ! -x "$(command -v docker)"  ]]; then
     sudo apt-get update -yqq
     sudo apt-get install \
          apt-transport-https \
          ca-certificates \
          curl \
          wget \
          gnupg-agent \
          software-properties-common -yqq
     curl --silent -fsSL https://raw.githubusercontent.com/docker/docker-install/master/install.sh | sudo bash > /dev/null 2>&1
     cp /opt/traefik/templates/local/local/daemon.j2 > /etc/docker/daemon.json
  fi
  mntcheck=$(docker volume ls | grep unionfs | head -n1 && echo true || echo false)
  if [[ $mntcheck == "false" ]]; then
     bash /opt/traefik/templates/local/install.sh >/dev/null 2>&1
     docker volume create -d local-persist -o mountpoint=/mnt --name=unionfs >/dev/null 2>&1
  fi
  networkcheck=$(docker network ls | grep "proxy" | tail -n 2 && echo true || echo false)
  if [[ $networkcheck == "false" ]]; then
      docker network create --driver=bridge proxy
  fi
  if [[ ! -x "$(command -v docker-compose)" ]]; then
     COMPOSE_VERSION=$(curl --silent -fsSL https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
     sh -c "curl --silent -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
     sh -c "curl --silent -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose"
     if [[ ! -L "/usr/bin/docker-compose" ]]; then
        rm -f /usr/bin/docker-compose && ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
     fi
     chmod a=rx,u+w /usr/local/bin/docker-compose >/dev/null 2>&1
     chmod a=rx,u+w /usr/bin/docker-compose >/dev/null 2>&1
  fi
  if [[ ! -x "$(command -v fail2ban-client)" ]]; then
     apt install fail2ban -yqq
  fi
  LOCALMOD=$(cat /etc/fail2ban/jail.local && echo true || echo false)
  MOD=$(cat /etc/fail2ban/jail.local | grep [authelia] && echo true || echo false)
  if [[ $LOCALMOD == "false" ]]; then
     cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
  fi
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
/etc/init.d/fail2ban restart
  fi
  optfolder="/opt/appdata"
  if [[ ! -d "${optfolder}/authelia" && ! -d "{optfolder}/traefik" ]]; then
     for i in ${optfolder}; do
     mkdir -p $i/{authelia,traefik,compose,portainer} \
              $i/traefik/{rules,acme}
     find $i -exec chown -hR 1000:1000 {} \;
  fi
  if [[ ! -f "/opt/appdata/authelia/configuration.yml" ]]; then
     cp /opt/traefik/templates/authelia/ /opt/appdata/authelia/
     cp /opt/traefik/templates/traefik/ /opt/appdata/traefik/
     cp /opt/traefik/templates/compose/ /opt/appdata/compose/
  fi
  touch /opt/appdata/traefik/acme/acme.json
  chmod 650 /opt/appdata/traefik/acme/acme.json
  touch /opt/appdata/authelia/authelia.log
  chmod 650 /opt/appdata/authelia/authelia.log
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
         sed -i '' "s/example.com/$DOMAIN/g" /opt/appdata/{compose,authelia}/{docker-compose.yml,configuration.yml}
         sed -i '' "s/example.com/$DOMAIN/g" /opt/appdata/traefik/rules/middlewares.toml
      else
         sed -i "s/example.com/$DOMAIN/g" /opt/appdata/{compose,authelia}/{docker-compose.yml,configuration.yml}
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
  else
    sed -i "s/<DISPLAYNAME>/$DISPLAYNAME/g" /opt/appdata/authelia/users_database.yml
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
  PASSWORD=$(docker run authelia/authelia authelia hash-password $PASSWORD | sed 's/Password hash: //g')
  JWTTOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  if [[ $(uname) == "Darwin" ]]; then
     sed -i '' "s/<PASSWORD>/$(echo $PASSWORD | sed -e 's/[\/&]/\\&/g')/g" /opt/appdata/authelia/users_database.yml
     sed -i '' "s/JWTTOKENID/$(echo $JWTTOKEN | sed -e 's/[\/&]/\\&/g')/g" /opt/appdata/authelia/configuration.yml
  else
     sed -i "s/<PASSWORD>/$(echo $PASSWORD | sed -e 's/[\/&]/\\&/g')/g" /opt/appdata/authelia/users_database.yml
     sed -i "s/JWTTOKENID/$(echo $JWTTOKEN | sed -e 's/[\/&]/\\&/g')/g" /opt/appdata/authelia/configuration.yml
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
    sed -i '' "s/EMAIL_ID/$EMAIL/g" /opt/appdata/{compose,authelia}/{docker-compose.yml,configuration.yml}
  else
    sed -i "s/EMAIL_ID/$EMAIL/g" /opt/appdata/{compose,authelia}/{docker-compose.yml,configuration.yml}
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
    sed -i '' "s/CFGLOBAL_ID/$CFGLOBAL/g" /opt/appdata/{compose,authelia}/{docker-compose.yml,configuration.yml}
  else
    sed -i "s/CFGLOBAL_ID/$CFGLOBAL/g" /opt/appdata/{compose,authelia}/{docker-compose.yml,configuration.yml}
  fi
else
  echo "CloudFlare-Global-Key cannot be empty"
  cfkey
fi
interface
}
deploynow() {

if [[ ! -f "/opt/appdata/authelia/done" ]]; then
   cd /opt/appdata/compose && docker-compose up -d
tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Treafikv2 with Authelia
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Traefikv2 with Authelia is deployed ; have fun ;-)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   touch /opt/appdata/authelia/done
   sleep 5 && interface
else
tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 ERROR Treafikv2 with Authelia
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Traefikv2 with Authelia is already deployed

Please remove the folder 

before you start again the deploy

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   sleep 5 && interface
fi
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
[4] CloudFlare-Email-Address          [ $EMAIL_ID ]
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
