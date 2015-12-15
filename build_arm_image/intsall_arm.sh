#!/bin/bash
# complete install with some specific ARM (raspberry) scripts.
#
# to be run for building an SD card image.
#

cp etc/init.d/yunohost-firstboot /etc/init.d/
chmod a+x /etc/init.d/yunohost-firstboot
insserv /etc/init.d/yunohost-firstboot
