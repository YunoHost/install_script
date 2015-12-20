= Build your own yunohost image for Raspberry Pi =

This folder contains helper scripts to build an arm image for raspberry.
The files here are for builder. They are not needed to install your yunohost.

The folder structure maps debian OS folders, shell script here are helpers.
Files in subfolders will be copied on the sdcard when installation is finished.

== License ==

All the content here is distributed under [GPLv3](http://www.gnu.org/licenses/gpl-3.0.txt).

== See also ==
* https://yunohost.org/#/build_arm_image for building steps explanations
* https://forum.yunohost.org/t/building-a-new-image-for-raspberry-debian-jessie-fr-en/1101/13 - discussion about building a new image for Raspberry Pi.

== Files ==

Descriptions of the files available here.

=== Run on PC ===

Scripts are prefixed by a number which is an hint of the order they should be ran.

==== autosizer.sh ==== 

Used on your PC to compact the dd image you will copy back after the rapsbian has been built.
This script requier root privilege to run and modify the local sdcard image.

==== 01_create_sdcard.sh ====

Create a bootable image for raspbian. You have to download the .zip of the image.
It embeds sudo call for using dd to copy the raw image to the sdcard. 
It will add an ssh key to pi default rasbian user in oder to connect later to continue automated installation. The pi user will be remonved at the end. The key-pair in generated only for you.

Usage:

~~~
./01_create_sdcard.sh image_rasbian.zip /dev/device_to_sdcard
~~~

It takes some minutes to perform all the steps. Be patient.

Use df or lsblk to find the name of your sdcard device. The script is taking care of umonting the partion if any. It also guess the disk's name if you give an partition's name instead of entire disk device's name.

==== 02_install_yunohost.sh ====

Should I say you have to plug the new sdcard freshly created and boot the Raspberry PI pluged on the same network as your PC?

The Raspberry has hopefully booted and is displaying a console's prompt:

~~~
Raspbian GNU/Linux 8 raspberrypi tty1

raspberrypi login:
~~~

If DHCP has done its job well, you also have an IP address on the Raspberry PI console screen:

~~~
My IP address is 192.168.1.123
~~~

Or what ever your DHCP is giving…

Run:

~~~
./02_install_yunohost.sh 192.168.1.123
~~~

=== Run on Raspberry ===

run the following script before shuting down your raspbian.

~~~
./intsall_arm.sh
~~~
