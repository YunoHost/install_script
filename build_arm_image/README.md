# Build your own yunohost image for Raspberry Pi

This folder contains helper scripts to build an arm image of yunohost for raspberry.
The files here are for builder. They are not needed to install your yunohost, the purpose is to reproduce the .img.
Of course you can try the step exlained here, and you will get a fresh yunohost at the end.

The folder etc/ structure maps debian OS folders, shell script here are helpers.
Files in etc/ subfolders will be copied on the sdcard when installation is finished.

Those scripts are following the steps provided here: https://yunohost.org/#/build_arm_image

### Notes:

`01_create_sdcard.sh` can be used to copy raspbian image to a sdcard and stop here, without yunohost.
An ssh key is added to remote access pi@raspbian account without passphrase.

Ex:
```
ssh -i _build_arm_steps/nopasskey pi@DHCP_IP
```

Don't forget to at first: `sudo raspbi-config` + enlarge file-system to have full size sdcard for your raspberry.
(also accomplished by: `sudo raspi-config --expand-rootfs`)
Enjoy.

## License
All the content here is distributed under [GPLv3](http://www.gnu.org/licenses/gpl-3.0.txt).

## See also
* https://forum.yunohost.org/t/building-a-new-image-for-raspberry-debian-jessie-fr-en/1101/13 - discussion about building a new image for Raspberry Pi.
* http://build.yunohost.org/ - some build here

## Files

Description of the files available here.

All step stripts are using your PC to store some files in the folder `_build_arm_steps/`.  This folder will be created by `01_create_sdcard.sh`. You can wipe it, or remove selected script data form it, to redo a step.

All step scripts are designed to run in this folder on your PC:

~~~bash
git clone this_repos
cd path_to/build_arm_image/
./01_create_sdcard.sh raspbian-jessie.zip /dev/mmcblk0
# plug and boot raspberrypi
./02_install_yunohost.sh 192.168.1.200
# unplug raspberrypi and connect the sdcard back to the PC
./03_copy_sdcard_to_img.sh /dev/mmcblk0
~~~

### Steps

Scripts are prefixed by a number which is the order they must be ran.

#### 01_create_sdcard.sh

Create a bootable image for raspbian. You have to download the .zip of the raspbian image.
([See:](https://www.raspberrypi.org/downloads/raspbian/)

This script embeds sudo call for using `dd` to copy the raw image to the sdcard. 
It will add an ssh key to `pi` default rasbian user in order to connect later to continue automated installation (See `02_install_yunohost.sh`)
The pi user will be removed at the end (Not yet, See #4). The ssh key-pair is generated only for you, in `_build_arm_steps/`

Usage:

~~~
./01_create_sdcard.sh image_rasbian.zip /dev/device_to_sdcard
~~~

It takes some minutes to perform all the steps (~ 2m3.867s at last run). Be patient.

Use commend like `df` or `lsblk` to find the name of your sdcard device. The script is taking care of umonting the partition if any. 
It also guesses the disk's name if you gave a partition's name instead of entire disk device's name. i
(ex: /dev/mmcblk0p2 --> /dev/mmcblk0)

BE CAREFULL not to wipe the wrong device!

#### 02_install_yunohost.sh

Should I say: you have to plug the new sdcard freshly created and boot the Raspberry PI pluged on the same network as your PC?

The Raspberry has hopefully booted and is displaying a console's prompt, which looks like:

~~~
Raspbian GNU/Linux 8 raspberrypi tty1

raspberrypi login:
~~~

If DHCP has done its job well, you also have an IP address on the Raspberry PI console screen:

~~~
My IP address is 192.168.1.123
~~~

Or what ever your DHCP is giving…

Run (on the PC, not the raspberry):

~~~bash
./02_install_yunohost.sh 192.168.1.123
~~~

This step is quite long. It took ~24min on my Raspberry. Be patient.
A message will be displayed on the screen to explain how you can watch it if you want.

If you got ssh `Host key verification failed.`, to fix it then:

~~~bash
rm _build_arm_steps/yuno_step*
# retry
./02_install_yunohost.sh 192.168.1.123
~~~

#### 03_copy_sdcard_to_img.sh

When the build is finished, the Raspberry will shutdown. Unplug and insert the sdcard back in the computer.

~~~bash
./03_copy_sdcard_to_img.sh /dev/sdcard_device
~~~

This will ask your sudo password and `dd` the resulting img from the sdcard back to your PC. 
Stored in `_build_arm_steps/` folder. It takes arround 6min on my PC to copy an sdcard of 8G.

The image will be automaticly shrinked to its minimal size using autosizer.sh. 


#### test the image back

You can test the resutling image back again with `01_create_sdcard.sh`.

~~~bash
./01_create_sdcard.sh _build_arm_steps/newly_created_image.img /dev/sdcard_device
~~~

#### share

You can zip, bzip2, or…, and share your freshly created yunohost image on the [forum](https://forum.yunohost.org).

Enjoy!

### Helper

#### autosizer.sh

Used on your PC to compact the dd image you will copy back after the rapsbian has been built.
This script requier root privilege to run and modify the local sdcard image.
