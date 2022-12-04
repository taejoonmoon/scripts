#!/bin/bash
# setup defaults
ENVIRONMENT="staging"
SALT_MASTER_DOMAIN="saltmaster.example.co.kr"
PS1_PROMPT="none"
MINION_ID=`hostname`

## display usage
usage() {
  echo "$0 [-e S] [-s S] [ -p S ] [ -m minion_id ]"
  echo "example) $0 -p consul -m infra-consul"
  echo "option"
  echo " -e: ENVIRONMENT (default : staging)"
  echo " -s: saltmaster domain (default : saltmaster.example.co.kr)"
  echo " -p: PS1 prompt (default : none)"
  echo " -m: minion_id (default : hostname - $HOSTNAME)"
}

while getopts "e:d:s:p:m:" opt; do
  case $opt in
    e)  ENVIRONMENT=$OPTARG ;;
    s)  SALT_MASTER_DOMAIN=$OPTARG ;;
    p)  PS1_PROMPT=$OPTARG ;;
    m)  MINION_ID=$OPTARG ;;
    \?) usage
        exit 1;;
    esac
done

shift $(($OPTIND-1))


echo "=========================================================="
echo "ENVIRONMENT : $ENVIRONMENT"
echo "SALT_MASTER_DOMAIN : $SALT_MASTER_DOMAIN"
echo "minion_id : $MINION_ID"
echo "PS1_PROMPT : $PS1_PROMPT"
echo "=========================================================="

# check ubuntu os
check_os() {
  if ! test -f /etc/lsb-release  ; then
    echo "Can't find /etc/lsb-release file. Only support Ubuntu."
    exit 1
  fi
}

# config PS1
update_ps1() {
  bashrc_lists="/root/.bashrc /home/ubuntu/.bashrc"
  for bashrc_list in $bashrc_lists; do
    if [ -f $bashrc_list ] ; then
      if ! egrep -q '^[^#]+\.[ ]+/etc/profile.d/ps1.sh' $bashrc_list ; then
        echo "test -f /etc/profile.d/ps1.sh && . /etc/profile.d/ps1.sh" >> $bashrc_list
        echo "$bashrc_list file updated for PS1 prompt."
      fi
    fi
  done

  if [ $PS1_PROMPT = "none" ]; then
    new_ps1="$ENVIRONMENT"
  else
    new_ps1="$ENVIRONMENT-$PS1_PROMPT"
  fi
  cat > /etc/profile.d/ps1.sh <<EOF
#!/bin/bash
PS1="[$new_ps1] \$PS1"
EOF

}

# install saltstack master or saltstack minion
install_salt() {

  package="salt-minion"

  if ! dpkg -l | egrep -q "^ii\s+$package" ; then
    export DEBIAN_FRONTEND=noninteractive
    apt-key list | egrep -iq saltstack || wget -O - https://repo.saltstack.com/apt/ubuntu/$(lsb_release -r -s)/amd64/2016.11/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
    sh -c 'echo "deb http://repo.saltstack.com/apt/ubuntu/$(lsb_release -r -s)/amd64/2016.11 $(lsb_release -c -s) main" > /etc/apt/sources.list.d/saltstack.list'
    apt update > /dev/null
    apt install -y $package > /dev/null && echo "installed $package pakcage."
  fi

  echo "$MINION_ID" > /etc/salt/minion_id
  echo "master: $SALT_MASTER_DOMAIN" > /etc/salt/minion
  systemctl restart salt-minion
  sleep 5
  systemctl restart salt-minion
  sleep 5
  salt-call state.apply --state-output=changes --state-verbose=False
  salt-call state.apply --state-output=changes --state-verbose=False

  # sshd restart with 7722 port
  if egrep -q "^Port[ ]+7722" /etc/ssh/sshd_config && netstat -atn | egrep -q "0.0.0.0:22" ; then
    systemctl restart sshd && echo "sshd restarted with 7722 port."
  fi

}

## main
check_os
update_ps1
install_salt
