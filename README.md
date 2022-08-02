# ezdns

Steps to add new subdomain in nameserver

1. edit /etc/bind/named.conf.local
add zone configuration as following

zone "mdm01.dd.ezbox.cc" {
        type master;
        file "/var/cache/bind/db.mdm01.dd.ezbox.cc";
        allow-update { 127.0.0.1; };
};

2. use gen-user.sh to generate new zone login authentication data

./gen-user.sh /etc/ezdns/passwd.db *.mdm01.dd.ezbox.cc
password is ????????=
Database /etc/ezdns/passwd.db updated.

3. set the username and password in update.sh

4. run update.sh in remote ezbox and update the IP address of remote ezbox to nameserver.


