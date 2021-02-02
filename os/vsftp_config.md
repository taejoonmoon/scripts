- 작업요약
ftp 프로그램으로 vsftpd 설치
ftp user로 ftpuser 추가. 패스워드는 임의로 생성하며 $ftp_passwd 에 나옴. 이 부분 까먹으면 수동으로 비밀번호 바꾸면 됩니다.
/etc/vsftpd/user_list 에 지정된 사용자만 ftp 접속 가능하므로 다른 user를 추가한다면 여기에 넣어주셔야 합니다. vsftpd는 재시작 필요하던가?




# check os
cat /etc/os-release  | grep PRETTY
PRETTY_NAME="CentOS Linux 7 (Core)"

# install vsftpd
rpm -qa | grep vsftpd || yum install -y vsftpd

# useradd ftpuser
useradd -m ftpuser

# ramdon password 생성.
ftp_passwd=`openssl rand -base64 32`

# 아래 변수에 나온 것이 ftpuser 사용자의 비밀번호
echo $ftp_passwd 

# passwd ftpuser
echo "$ftp_passwd" | passwd --stdin ftpuser

# update selinux
sed -e 's/SELINUX=enforcing/SELINUX=disabled/g' -i /etc/selinux/config


# config vsftpd.conf
test -f /etc/vsftpd/vsftpd.conf && cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.backup

cat << EOF > /etc/vsftpd/vsftpd.conf
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=YES
listen_ipv6=NO

pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES

userlist_deny=NO
EOF

# config ftp allow user. ftp 로그인하려면 여기에 추가해야 함.
cat << EOF > /etc/vsftpd/user_list
ftpuser
EOF

# enable and start vsftpd
systemctl enable vsftpd
systemctl restart vsftpd

# check vsftpd
systemctl status vsftpd
ps auxw | grep vsftp


# ftp test : lftp 프로그램 있으면 아래와 같이 하면 됨. xxx는 위에서 만든 비밀번호 사용. 실제 ip를 이용하여 다른 서버에서 접속 확인을 해보는것이 좋음.
lftp -u ftpuser,xxx localhost
ftp localhost

