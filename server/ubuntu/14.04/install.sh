#!/bin/bash

# install apache2 configuration
cp -af ./apache2/* /etc/apache2/ -af
#a2ensite ezdns-default.conf
a2ensite ezdns-default-ssl.conf
a2enmod authn_dbm

# install ezdns configuration
mkdir -p /etc/ezdns
cp -af ./ezdns/* /etc/ezdns/
#htdbm -c /etc/ezdns/passwd.db test

# install WWW web pages
mkdir -p /var/www
cp -af ./www/* /var/www/

# restart apache2 server
/etc/init.d/apache2 restart

# prepare bind9
mkdir -p /var/cache/bind/dlz
chown bind.bind /var/cache/bind/dlz

cp -af ./bind9/named.conf /etc/bind/
cp -af ./bind9/named.conf.dlzbdb /etc/bind/
