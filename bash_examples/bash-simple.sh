#!/bin/bash

configure_nfs() {
  nfs_package="nfs-common"
  if ! dpkg -l | egrep -q "^ii\s+$nfs_package" ; then
    export DEBIAN_FRONTEND=noninteractive
    apt install -y $nfs_package > /dev/null && echo "installed $nfs_package pakcage."
  fi

  test -d /data || mkdir -v /data

  nfs_server="fs-b31befd2.efs.ap-northeast-2.amazonaws.com"

  if ! mount | grep -q "/data" ; then
    mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $nfs_server:/ /data && echo "mount $nfs_server to /data"
  else
    echo "already mounted $nfs_server to /data"
  fi
  if ! grep -q $nfs_server /etc/fstab ; then
    echo "$nfs_server:/ /data nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport  0 0" >> /etc/fstab && echo "added /data to /etc/fstab"
  fi
}

configure_example_salt() {
  example_role=$1

  salt-call state.apply users --state-output=changes --state-verbose=False
  salt-call state.apply ssh.sshd --state-output=changes --state-verbose=False

  # sshd restart with 7722 port
  if egrep -q "^Port[ ]+7722" /etc/ssh/sshd_config && netstat -atn | egrep -q "0.0.0.0:22" ; then
    systemctl restart sshd && echo "sshd restarted with 7722 port."
  fi

  cat > /etc/salt/minion <<EOF
master: saltmaster.yogiyo.co.kr

grains:
  roles:
    - example
  example_roles:
    - ${example_role}
EOF
  systemctl restart salt-minion
  salt-call state.apply --state-output=changes --state-verbose=False

}

## main
example_role=$1

if [ -z $example_role ]; then
  echo "not found example role"
  exit 1
fi

configure_nfs

configure_example_salt $example_role
