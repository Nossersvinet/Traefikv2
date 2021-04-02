#!/bin/bash
#
# Title:      Traefikv2 with Authelia over Cloudflare
# OS Branch:  ubuntu,debian,rasbian
# Author(s):  mrdoob
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

updatesystem() {
if [[ $EUID -ne 0 ]];then
tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔  You must execute as a SUDO user (with sudo) or as ROOT!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
exit 0
fi
while true; do
  basefolder="/opt/appdata"
  oldsinstall && proxydel
  package_list="update upgrade dist-upgrade autoremove autoclean"
  for i in ${package_list}; do
      echo "running now $i"
      $(command -v apt) $i -yqq 1>/dev/null 2>&1
  done
  if [[ ! -d "/mnt/downloads" && ! -d "/mnt/unionfs" ]];then
     basefolder="/mnt"
     for i in ${basefolder}; do
         $(command -v mkdir) -p $i/{unionfs,downloads,incomplete,torrent,nzb} \
                  $i/{incomplete,downloads}/{nzb,torrent}/{movies,tv,tv4k,movies4k,movieshdr,tvhdr,remux} \
                  $i/{torrent,nzb}/watch
        $(command -v find) $i -exec $(command -v chmod) a=rx,u+w {} \;
        $(command -v find) $i -exec $(command -v chown) -hR 1000:1000 {} \;
     done
  fi
  config="/etc/sysctl.d/99-sysctl.conf"
  ipv6=$(cat $config | grep -qE 'ipv6' && echo true || false)
  if [[ -f $config ]];then
     if [ $ipv6 != 'true' ] || [ $ipv6 == 'true' ];then
       grep -qE 'net.ipv6.conf.all.disable_ipv6 = 1' $config || \
            echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> $config
       grep -qE 'net.ipv6.conf.default.disable_ipv6 = 1' $config || \
            echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> $config
       grep -qE 'net.ipv6.conf.lo.disable_ipv6 = 1' $config || \
            echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> $config
       sysctl -p -q
     fi
  fi
  if [[ ! -x $(command -v docker) ]];then
     if [[ -r /etc/os-release ]];then lsb_dist="$(. /etc/os-release && echo "$ID")"; fi
        package_listubuntu="apt-transport-https ca-certificates curl wget gnupg-agent software-properties-common language-pack-en-base pciutils lshw nano rsync fuse"
        package_listdebian="apt-transport-https ca-certificates curl wget gnupg-agent gnupg2 software-properties-common language-pack-en-base pciutils lshw nano rsync fuse"
     if [[ $lsb_dist == 'ubuntu' ]] || [[ $lsb_dist == 'rasbian' ]];then
        for i in ${package_listubuntu}; do
            echo "Now installing $i"
            $(command -v apt) install $i --reinstall -yqq 1>/dev/null 2>&1
            sleep 1
        done
     else
        for i in ${package_listdebian}; do
            echo "Now installing $i"
            $(command -v apt) install $i --reinstall -yqq 1>/dev/null 2>&1
            sleep 1
        done
     fi
     $(command -v curl) --silent -fsSL https://raw.githubusercontent.com/docker/docker-install/master/install.sh | sudo bash > /dev/null 2>&1
     cp /opt/traefik/templates/local/daemon.j2 /etc/docker/daemon.json
  else
     cp /opt/traefik/templates/local/daemon.j2 /etc/docker/daemon.json
     $(command -v curl) --silent -fsSL https://raw.githubusercontent.com/docker/docker-install/master/install.sh | sudo bash > /dev/null 2>&1
  fi
     dockergroup=$(grep -qE docker /etc/group && echo true || echo false)
  if [[ $dockergroup == "false" ]];then usermod -aG docker $(whoami);fi
     dockertest=$($(command -v systemctl) is-active docker | grep -qE 'active' && echo true || echo false)
  if [[ $dockertest != "false" ]];then $(command -v systemctl) reload-or-restart docker.service 1>/dev/null 2>&1 && $(command -v systemctl) enable docker.service >/dev/null 2>&1; fi
     mntcheck=$($(command -v docker) volume ls | grep -qE 'unionfs' && echo true || echo false)
  if [[ $mntcheck == "false" ]];then
     $(command -v curl) --silent -fsSL https://raw.githubusercontent.com/MatchbookLab/local-persist/master/scripts/install.sh | sudo bash 1>/dev/null 2>&1
     $(command -v docker) volume create -d local-persist -o mountpoint=/mnt --name=unionfs
  fi
     networkcheck=$($(command -v docker) network ls | grep -qE 'proxy' && echo true || echo false)
  if [[ $networkcheck == "false" ]];then $(command -v docker) network create --driver=bridge proxy 1>/dev/null 2>&1; fi
  if [[ ! -x $(command -v docker-compose) ]];then
     COMPOSE_VERSION=$($(command -v curl) --silent -fsSL https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
     sh -c "curl --silent -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
     sh -c "curl --silent -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose"
     if [[ ! -L "/usr/bin/docker-compose" ]];then $(command -v rm) -f /usr/bin/docker-compose && ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose;fi
     $(command -v chmod) a=rx,u+w /usr/local/bin/docker-compose >/dev/null 2>&1
     $(command -v chmod) a=rx,u+w /usr/bin/docker-compose >/dev/null 2>&1
  fi
     dailyapt=$($(command -v systemctl) is-active apt-daily | grep -qE 'active' && echo true || echo false)
     dailyupg=$($(command -v systemctl) is-active apt-daily-upgrade | grep -qE 'active' && echo true || echo false)
  if [[ $dailyapt == "true" || $dailyupg == "true" ]];then
     disable="apt-daily.service apt-daily.timer apt-daily-upgrade.timer apt-daily-upgrade.service"
     for i in ${disable};do
        systemctl disable $i >/dev/null 2>&1
     done
  fi
  if [[ "$(systemd-detect-virt)" == "lxc" ]];then $(command -v bash) ./.subinstall/lxc.sh;fi
  if [[ -x $(command -v lshw) ]];then
     gpu="ntel NVIDIA"
     for i in ${gpu}; do
         TDV=$(lspci | grep -i --color 'vga\|3d\|2d' | grep -E $i 1>/dev/null 2>&1 && echo true || echo false)
         if [[ $TDV == "true" ]];then $(command -v bash) ./templates/local/gpu.sh;fi
     done
  fi
  if [[ ! -x $(command -v ansible) ]];then
     if [[ -r /etc/os-release ]];then lsb_dist="$(. /etc/os-release && echo "$ID")";fi
        package_list="ansible dialog python3-lxml"
        package_listdebian="apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367"
        package_listubuntu="apt-add-repository --yes --update ppa:ansible/ansible"
        if [[ $lsb_dist == 'ubuntu' ]] || [[ $lsb_dist == 'rasbian' ]];then ${package_listubuntu} 1>/dev/null 2>&1;else ${package_listdebian} >/dev/null 2>1;fi
        for i in ${package_list}; do
            $(command -v apt) install $i --reinstall -yqq 1>/dev/null 2>&1
        done
        if [[ $lsb_dist == 'ubuntu' ]];then sudo add-apt-repository --remove ppa:ansible/ansible;fi
  fi
     invet="/etc/ansible/inventories"
     conf="/etc/ansible/ansible.cfg"
     loc="local"
     if [[ ! -d $invet ]];then $(command -v mkdir) -p $invet >/dev/null 2>1;fi
        if [[ ! -f $invet/$loc ]];then
        echo "\
[local]
127.0.0.1 ansible_connection=local" > $invet/$loc
     fi
     grep -qE "inventory      = /etc/ansible/inventories/local" $conf || \
          echo "inventory      = /etc/ansible/inventories/local" >> $conf
  if [[ ! -x $(command -v fail2ban-client) ]];then $(command -v apt) install fail2ban -yqq 1>/dev/null 2>&1; fi
     while true; do
         f2ban=$($(command -v systemctl) is-active fail2ban | grep -qE 'active' && echo true || echo false)
         if [[ $f2ban != 'true' ]];then
            echo "Waiting for fail2ban to start" && sleep 1 && continue
         else
            break
         fi
     done
     ORGFILE="/etc/fail2ban/jail.conf"
     LOCALMOD="/etc/fail2ban/jail.local"
  if [[ ! -f $LOCALMOD ]];then cp $ORGFILE $LOCALMOD; fi
     MOD=$(cat $LOCALMOD | grep -qE '\[authelia\]' && echo true || echo false)
  if [[ $MOD == "false" ]];then
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
  f2ban=$($(command -v systemctl) is-active fail2ban | grep -qE 'active' && echo true || echo false)
  if [[ $f2ban != "false" ]];then
     $(command -v systemctl) reload-or-restart fail2ban.service 1>/dev/null 2>&1
     $(command -v systemctl) enable fail2ban.service 1>/dev/null 2>&1
  fi
  if [[ ! -x $(command -v rsync) ]];then $(command -v apt) install --reinstall rsync -yqq 1>/dev/null 2>&1;fi
  $(command -v rsync) /opt/traefik/templates/ /opt/appdata/ -aq --info=progress2 -hv --exclude={'local','installer'}
  basefolder="/opt/appdata"
  for i in ${basefolder}; do
      $(command -v mkdir) -p $i/{authelia,traefik,compose} \
               $i/traefik/{rules,acme}
      $(command -v find) $i/{authelia,traefik,compose} -exec $(command -v chown) -hR 1000:1000 {} \;
  done
  $(command -v touch) ${basefolder}/traefik/acme/acme.json \
        ${basefolder}/traefik/traefik.log \
        ${basefolder}/authelia/authelia.log
  $(command -v chmod) 600 ${basefolder}/traefik/traefik.log \
            ${basefolder}/authelia/authelia.log \
            ${basefolder}/traefik/acme/acme.json
  break
done
interface
}
oldsinstall() {
  oldsolutions="plexguide cloudbox gooby"
  for i in ${oldsolutions}; do
      folders="/var/ /opt/ /home/"
      for ii in ${folders}; do
          show=$(find $ii -maxdepth 1 -type d -name $i -print)
          if [[ $show != '' ]];then
             echo ""
             printf "\033[0;31m You need to reinstall your operating system. 
sorry, you need a freshly installed server. We can not install on top of $i\033[0m\n"
             echo ""
             read -erp "Type confirm when you have read the message: " input
             if [[ "$input" = "confirm" ]];then exit ;else oldsinstall;fi
          fi
      done
  done
}
proxydel() {
delproxy="apache2 nginx"
for i in ${delproxy}; do
    $(command -v systemctl) stop $i 1>/dev/null 2>&1
    $(command -v systemctl) disable $i 1>/dev/null 2>&1
    $(command -v apt) remove $i -yqq 1>/dev/null 2>&1
    $(command -v apt) purge $i -yqq 1>/dev/null 2>&1
done
}
########## FUNCTIONS START
domain() {
basefolder="/opt/appdata"
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Treafikv2 Domain
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DNS records will not be automatically added with the following 
TLD Domains 

.a, .cf, .ga, .gq, .ml or .tk 

Cloudflare has limited their API so you will have to manually add these 
records yourself via the Cloudflare dashboard.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   read -erp "Which domain would you like to use?: " DOMAIN

if [[ $DOMAIN == "" ]];then
   echo "Domain cannot be empty"
   domain
else
   MODIFIED=$(cat /etc/hosts | grep $DOMAIN && echo true || echo false)
   if [[ $MODIFIED == "false" ]];then
   echo "\
127.0.0.1  *.$DOMAIN
127.0.0.1  $DOMAIN" >> /etc/hosts
   fi
   if [[ $DOMAIN != "example.com" ]];then
      if [[ $(uname) == "Darwin" ]];then
         sed -i '' "s/example.com/$DOMAIN/g" $basefolder/authelia/configuration.yml
         sed -i '' "s/example.com/$DOMAIN/g" $basefolder/compose/docker-compose.yml
         sed -i '' "s/example.com/$DOMAIN/g" $basefolder/traefik/rules/middlewares.toml
      else
         sed -i "s/example.com/$DOMAIN/g" $basefolder/authelia/configuration.yml
         sed -i "s/example.com/$DOMAIN/g" $basefolder/compose/docker-compose.yml
         sed -i "s/example.com/$DOMAIN/g" $basefolder/traefik/rules/middlewares.toml
         sed -i "s/example.com/$DOMAIN/g" $basefolder/compose/.env
      fi
   fi
fi
interface
}
displayname() {
basefolder="/opt/appdata"
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Authelia Username
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   read -erp "Enter your username for Authelia (eg. John Doe): " DISPLAYNAME

if [[ $DISPLAYNAME != "" ]];then
   if [[ $(uname) == "Darwin" ]];then
      sed -i '' "s/<DISPLAYNAME>/$DISPLAYNAME/g" $basefolder/authelia/users_database.yml
      sed -i '' "s/<USERNAME>/$DISPLAYNAME/g" $basefolder/authelia/users_database.yml
   else
      sed -i "s/<DISPLAYNAME>/$DISPLAYNAME/g" $basefolder/authelia/users_database.yml
      sed -i "s/<USERNAME>/$DISPLAYNAME/g" $basefolder/authelia/users_database.yml
   fi
else
  echo "Display name cannot be empty"
  displayname
fi
interface
}

password() {
basefolder="/opt/appdata"
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Authelia Password
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   read -erp "Enter a password for $USERNAME: " PASSWORD

if [[ $PASSWORD != "" ]];then
   $(command -v docker) pull authelia/authelia -q > /dev/null
   PASSWORD=$($(command -v docker) run authelia/authelia authelia hash-password $PASSWORD -i 2 -k 32 -m 128 -p 8 -l 32 | sed 's/Password hash: //g')
   JWTTOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
   SECTOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
   if [[ $(uname) == "Darwin" ]];then
      sed -i '' "s/<PASSWORD>/$(echo $PASSWORD | sed -e 's/[\/&]/\\&/g')/g" $basefolder/authelia/users_database.yml
      sed -i '' "s/JWTTOKENID/$(echo $JWTTOKEN | sed -e 's/[\/&]/\\&/g')/g" $basefolder/authelia/configuration.yml
      sed -i '' "s/unsecure_session_secret/$(echo $SECTOKEN | sed -e 's/[\/&]/\\&/g')/g" $basefolder/authelia/configuration.yml
   else
      sed -i "s/<PASSWORD>/$(echo $PASSWORD | sed -e 's/[\/&]/\\&/g')/g" $basefolder/authelia/users_database.yml
      sed -i "s/JWTTOKENID/$(echo $JWTTOKEN | sed -e 's/[\/&]/\\&/g')/g" $basefolder/authelia/configuration.yml
      sed -i "s/unsecure_session_secret/$(echo $SECTOKEN | sed -e 's/[\/&]/\\&/g')/g" $basefolder/authelia/configuration.yml
   fi
else
   echo "Password cannot be empty"
   password
fi
interface
}
cfemail() {
basefolder="/opt/appdata"
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Cloudflare Email-Address
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   read -erp "What is your CloudFlare Email Address : " EMAIL

if [[ $EMAIL != "" ]];then
   if [[ $(uname) == "Darwin" ]];then
      sed -i '' "s/example-CF-EMAIL/$EMAIL/g" $basefolder/authelia/{configuration.yml,users_database.yml}
      sed -i '' "s/example-CF-EMAIL/$EMAIL/g" $basefolder/compose/docker-compose.yml
   else
      sed -i "s/example-CF-EMAIL/$EMAIL/g" $basefolder/authelia/{configuration.yml,users_database.yml}
      sed -i "s/example-CF-EMAIL/$EMAIL/g" $basefolder/compose/docker-compose.yml
   fi
else
  echo "CloudFlare Email Address cannot be empty"
  cfemail
fi
interface
}
cfkey() {
basefolder="/opt/appdata"
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Cloudflare Global-Key
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   read -erp "What is your CloudFlare Global Key: " CFGLOBAL

if [[ $CFGLOBAL != "" ]];then
   if [[ $(uname) == "Darwin" ]];then
      sed -i '' "s/example-CF-API-KEY/$CFGLOBAL/g" $basefolder/authelia/configuration.yml
      sed -i '' "s/example-CF-API-KEY/$CFGLOBAL/g" $basefolder/compose/docker-compose.yml
   else
      sed -i "s/example-CF-API-KEY/$CFGLOBAL/g" $basefolder/authelia/configuration.yml
      sed -i "s/example-CF-API-KEY/$CFGLOBAL/g" $basefolder/compose/docker-compose.yml
   fi
else
   echo "CloudFlare Global Key cannot be empty"
   cfkey
fi
interface
}
cfzoneid() {
basefolder="/opt/appdata"
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Cloudflare Zone-ID
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
   read -erp "Whats your CloudFlare Zone ID: " CFZONEID

if [[ $CFZONEID != "" ]];then
   if [[ $(uname) == "Darwin" ]];then
      sed -i '' "s/example-CF-ZONE_ID/$CFZONEID/g" $basefolder/compose/docker-compose.yml
   else
      sed -i "s/example-CF-ZONE_ID/$CFZONEID/g" $basefolder/compose/docker-compose.yml
   fi
else
   echo "CloudFlare Zone ID cannot be empty"
   cfzoneid
fi
interface
}

jounanctlpatch() {
CTPATCH=$(cat /etc/systemd/journald.conf | grep "#PATCH" && echo true || echo false)
if [[ $CTPATCH == "false" ]];then
   journalctl --flush 1>/dev/null 2>&1
   journalctl --rotate 1>/dev/null 2>&1
   journalctl --vacuum-time=1s 1>/dev/null 2>&1
   $(command -v find) /var/log -name "*.gz" -delete 1>/dev/null 2>&1
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
basefolder="/opt/appdata"
SERVERIP=$(curl -s http://whatismijnip.nl |cut -d " " -f 5)
if [[ $SERVERIP != "" ]];then
   if [[ $(uname) == "Darwin" ]];then
      sed -i '' "s/SERVERIP_ID/$SERVERIP/g" $basefolder/authelia/configuration.yml
      sed -i '' "s/SERVERIP_ID/$SERVERIP/g" $basefolder/compose/.env
   else
      sed -i "s/SERVERIP_ID/$SERVERIP/g" $basefolder/authelia/configuration.yml
      sed -i "s/SERVERIP_ID/$SERVERIP/g" $basefolder/compose/.env
   fi
else
   echo "Server IP cannot be empty"
   serverip
fi
}

ccont() {
container=$($(command -v docker) ps -aq --format '{{.Names}}' | grep -E 'trae|auth|error-pag')
for i in ${container}; do
    $(command -v docker) stop $i 1>/dev/null 2>&1
    $(command -v docker) rm $i 1>/dev/null 2>&1
    $(command -v docker) image prune -af 1>/dev/null 2>&1
done
}
timezone() {
TZTEST=$($(command -v timedatectl) && echo true || echo false)
TZONE=$($(command -v timedatectl) | grep "Time zone:" | awk '{print $3}')
if [[ $TZTEST != "false" ]];then
   if [[ $TZONE != "" ]];then
      if [[ -f $basefolder/compose/.env ]];then sed -i '/TZ=/d' $basefolder/compose/.env;fi
      TZ=$TZONE 
      grep -qE 'TZ=$TZONE' $basefolder/compose/.env || \
           echo "TZ=$TZONE" >> $basefolder/compose/.env
   fi
fi
}
cleanup() {
listexited=$($(command -v docker) ps -aq --format '{{.State}}' | grep -E 'exited' | awk '{print $1}')
for i in ${listexited}; do
    $(command -v docker) rm $i 1>/dev/null 2>&1
done
$(command -v docker) image prune -af 1>/dev/null 2>&1
}
envcreate() {
basefolder="/opt/appdata"
env0=$basefolder/compose/.env
if [[ -f $env0 ]];then
   grep -qE 'ID=1000' $basefolder/compose/.env || \
       echo 'ID=1000' >> $basefolder/compose/.env
fi
}
lang(){
update-locale LANG=LANG=LC_ALL=en_US.UTF-8 LANGUAGE 1>/dev/null 2>&1
localectl set-locale LANG=LC_ALL=en_US.UTF-8 1>/dev/null 2>&1
}
#setarecord(){
### unfinished 
#if [[ ! -x $(command -v jq) ]];then $(command -v apt) install --reinstall jq -yqq 1>/dev/null 2>&1;fi
#zone=$DOMAIN
#dnsrecord=$DOMAIN
#cloudflare_auth_email=$EMAIL
#cloudflare_auth_key=$CFGLOBAL

#zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone&status=active" \
#  -H "X-Auth-Email: $cloudflare_auth_email" \
#  -H "Authorization: Bearer $cloudflare_auth_key" \
#  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

#dnsrecordid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=A&name=$dnsrecord" \
#  -H "X-Auth-Email: $cloudflare_auth_email" \
#  -H "Authorization: Bearer $cloudflare_auth_key" \
#  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

#curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$dnsrecordid" \
#  -H "X-Auth-Email: $cloudflare_auth_email" \
#  -H "Authorization: Bearer $cloudflare_auth_key" \
#  -H "Content-Type: application/json" \
# --data "{\"type\":\"A\",\"name\":\"$dnsrecord\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":false}" | jq
#}

##############
deploynow() {
basefolder="/opt/appdata"
compose="compose/docker-compose.yml"
#setarecord
lang
envcreate
timezone
cleanup
jounanctlpatch
serverip
ccont
#cd $basefolder/compose && $(command -v docker-compose) up -d --force-recreate 1>/dev/null 2>&1 && sleep 5
if [[ -f $basefolder/$compose ]];then
   $(command -v cd) $basefolder/compose/
   $(command -v docker-compose) config 1>/dev/null 2>&1
   code=$?
   if [[ $code -ne 0 ]];then
tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ❌ ERROR
    compose check has failed
    Return code is ${code}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
  read -erp "Confirm Info | PRESS [ENTER]" typed </dev/tty
clear && interface
   else
   $(command -v docker-compose) up -d --force-recreate 1>/dev/null 2>&1
   source $basefolder/compose/.env
   tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀 Treafikv2 with Authelia
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	   Traefikv2 with Authelia is deployed
      Please Wait some minutes Authelia and Treafik 
	 need some minutes to start all services

        Access to the apps are only over https://

        Authelia:   https://authelia.${DOMAIN}
        Traefik:    https://traefik.${DOMAIN}
        Portainer:  https://portainer.${DOMAIN}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
   fi
 fi
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
[6] CloudFlare-Zone-ID                [ $CFZONEID ]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[D] Deploy Traefikv2 with Authelia

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Z] - Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
  read -erp '↘️  Type Number | Press [ENTER]: ' typed </dev/tty

  case $typed in

     1) domain && clear && interface ;;
     2) displayname && clear && interface ;;
     3) password && clear && interface ;;
     4) cfemail && clear && interface ;;
     5) cfkey && clear && interface ;;
     6) cfzoneid && clear && interface ;;
     d) deploynow && clear && interface ;;
     D) deploynow && clear && interface ;;
     z) exit 0 ;;
     Z) exit 0 ;;
     *) clear && interface ;;

  esac
}
# FUNCTIONS END ##############################################################
updatesystem
