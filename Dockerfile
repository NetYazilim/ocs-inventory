FROM alpine:edge
LABEL maintainer "Levent SAGIROGLU <LSagiroglu@gmail.com>"

ARG VERSION=2.6RC

EXPOSE 80
ENV OCS_DBHOST ""
ENV OCS_DBNAME ""  
ENV OCS_DBUSER ""
ENV OCS_DBPASS ""

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories 
RUN apk add --update --no-cache bash tar gzip wget make apache2 \ 
            php7-apache2 php7 php7-mysqli php7-pdo_mysql php7-gd php7-memcached \
            php7-snmp php7-xml php7-simplexml php7-json php7-pspell php7-mbstring php7-zip php7-soap php7-curl \
            py-pip libxml2 perl-xml-simple perl-digest-sha1 perl-compress-raw-zlib perl-dbi \
            perl-dbd-mysql perl-net-ip perl-soap-lite apache2-mod-perl perl-switch
############# php7-xmlrpc php7-xmlreader php7-xmlwriter
WORKDIR /tmp/
RUN wget https://www.cpan.org/authors/id/P/PH/PHRED/Apache-DBI-1.12.tar.gz
RUN tar -xvf Apache-DBI-1.12.tar.gz
WORKDIR /tmp/Apache-DBI-1.12
RUN perl Makefile.PL ;\
    make ;\
    make install

#############
WORKDIR /tmp/ocs-setup/
RUN wget https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/${VERSION}/OCSNG_UNIX_SERVER_2.6_RC.tar.gz
RUN tar -xvf OCSNG_UNIX_SERVER_*.tar.gz --strip 1
WORKDIR /tmp/ocs-setup/Apache
RUN perl Makefile.PL ;\
    make ;\
    make install ;\
    cp -R blib/lib/Apache /usr/local/share/perl5/ ;\
    cp /tmp/ocs-setup/etc/logrotate.d/ocsinventory-server /etc/logrotate.d/ ;\
#         mkdir -p /etc/ocsinventory-server/{plugins,perl} ;\
    bash -c 'mkdir -p /etc/ocsinventory-server/{plugins,perl}' ;\
    mkdir -p /usr/share/ocsinventory-reports/ocsreports/upload

WORKDIR /tmp/ocs-setup/
RUN cp -R ocsreports /usr/share/ocsinventory-reports/ ;\
    chown root:apache -R /usr/share/ocsinventory-reports/ocsreports ;\
#   mkdir -p /var/lib/ocsinventory-reports/{download,ipd,logs,scripts,snmp} ;\
    bash -c 'mkdir -p /var/lib/ocsinventory-reports/{download,ipd,logs,scripts,snmp}' ;\
    chmod -R +w /var/lib/ocsinventory-reports ;\
    chmod -R 777 /usr/share/ocsinventory-reports/ocsreports/plugins  ;\
    chmod -R 777 /usr/share/ocsinventory-reports/ocsreports/config  ;\
    chmod -R 777 /usr/share/ocsinventory-reports/ocsreports/upload  ;\
#   chown root:apache -R /var/lib/ocsinventory-reports/{download,ipd,logs,scripts,snmp} ;\
    bash -c 'chown root:apache -R /var/lib/ocsinventory-reports/{download,ipd,logs,scripts,snmp}' ;\
    cp binutils/ipdiscover-util.pl /usr/share/ocsinventory-reports/ocsreports/ipdiscover-util.pl ;\
    chown root:apache /usr/share/ocsinventory-reports/ocsreports/ipdiscover-util.pl ;\
    chmod 755 /usr/share/ocsinventory-reports/ocsreports/ipdiscover-util.pl
    
RUN sed -i 's,LoadModule mpm_event_module find /mod_mpm_event.so,LoadModule mpm_prefork_module modules/mod_mpm_prefork.so,g' /etc/apache2/httpd.conf
RUN sed -i 's/DirectoryIndex index\.html/DirectoryIndex index\.php/g' /etc/apache2/httpd.conf
RUN sed -i 's,post_max_size = 8M,post_max_size = 101M,g' /etc/php7/php.ini
RUN sed -i 's,upload_max_filesize = 2M,upload_max_filesize =101M,g' /etc/php7/php.ini 
                      
COPY *.conf /etc/apache2/conf.d/
#### OPTIONAL PLUGINS #####################################################
WORKDIR /usr/share/ocsinventory-reports/ocsreports/download
# uptime - Retrieve Machine Uptime
RUN wget https://github.com/PluginsOCSInventory-NG/uptime/releases/download/2.0/uptime.zip
# officepack 
RUN wget https://github.com/PluginsOCSInventory-NG/officepack/releases/download/3.0/officepack.zip
# vmware-vcenter
RUN wget https://github.com/PluginsOCSInventory-NG/vmware-vcenter/releases/download/2.0/vmware_vcenter.zip
# winupdate
RUN wget https://github.com/PluginsOCSInventory-NG/winupdate/releases/download/2.0/winupdate.zip
############################################################################
COPY *.php /usr/share/ocsinventory-reports/ocsreports/
# RUN chown root:apache /usr/share/ocsinventory-reports/ocsreports/removeinstall.php ;\
RUN chown root:apache /usr/share/ocsinventory-reports/ocsreports/dbconfig.inc.php ;\
    chmod 777 /usr/share/ocsinventory-reports/ocsreports/dbconfig.inc.php

# httpd -D FOREGROUND çalışması için 
RUN mkdir -p /run/apache2  
RUN echo "ServerName localhost" >> /etc/apache2/httpd.conf

RUN mkdir -p /var/log/ocsinventory-server/ 
# RUN rm /usr/share/ocsinventory-reports/ocsreports/install.php
RUN rm -rf /tmp/*

CMD ["httpd", "-D", "FOREGROUND"]