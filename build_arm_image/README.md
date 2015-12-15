This folder contains helper scripts to build an arm image for raspberry.
The files here are for builder. They are not needed to install yunohost.

The folder structure maps debian OS folders, shell script here are helpers.

The files are copied on the sdcard when installation is finished.

See also: https://yunohost.org/#/build_arm_image for previous step.

run the following script before shuting down your rasbian.

~~~
./intsall_arm.sh
~~~


autosizer.sh is used on your PC to compact the dd image you will copy back.
this script requier root privilege to run and modify the sdcard image.
