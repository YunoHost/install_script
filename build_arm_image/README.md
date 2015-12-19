= Build your own yunohost image for Raspberry Pi =

This folder contains helper scripts to build an arm image for raspberry.
The files here are for builder. They are not needed to install yunohost.

The folder structure maps debian OS folders, shell script here are helpers.
The files are copied on the sdcard when installation is finished.

== See also ==
* https://yunohost.org/#/build_arm_image for buildini step explanations
* https://forum.yunohost.org/t/building-a-new-image-for-raspberry-debian-jessie-fr-en/1101/13 - discussion about building an new image for Raspberry Pi.

== Files ==

Descriptions of the files available here.

=== Run on PC ===

Scripts are prefixed by a number which is an hint of the order they should be ran.

==== autosizer.sh ==== 

Used on your PC to compact the dd image you will copy back.
this script requier root privilege to run and modify the sdcard image.

==== 01_create_sdcard.sh ====

Create a bootable image for raspbian. You have to download the .zip of the image.
it embeds sudo call for using dd to copy the raw image to the sdcard.

Usage:

~~~
./01_create_sdcard.sh image_rasbian.zip /dev/device_to_sdcard
~~~

it takes some minutes to perform all the steps. Be patient.


=== Run on Raspberry ===

run the following script before shuting down your raspbian.

~~~
./intsall_arm.sh
~~~
