FROM        debian:wheezy
MAINTAINER  kload "kload@kload.fr"

RUN rm /usr/sbin/policy-rc.d
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get update
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install apt-utils -qq -y --force-yes
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install git -qq -y --force-yes
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install bind9 -qq -y --force-yes
RUN rm /var/lib/dpkg/info/bind9*
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -f
ADD . /tmp/install_script

RUN cd /tmp/install_script && LC_ALL=C DEBIAN_FRONTEND=noninteractive ./autoinstall_yunohostv2 test || :
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install ssh -qq -y --force-yes
RUN rm -rf /var/lib/apt/lists/*
RUN apt-get clean

RUN service slapd start && yunohost tools postinstall -d mydomain.com -p changeme

EXPOSE 22 25 53/udp 443 465 993 5222 5269 5290
CMD /sbin/init
