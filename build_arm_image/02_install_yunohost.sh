#!/bin/bash
#
# Usage: ./02_install_yunohost.sh DHCP_IP_ADDRESS_OF_RASPBERRYPI
#
# Doc: See README.md
#
# STEPS:
#  1. enlarge filesystem with raspi-config --expand-rootfs and reboot
#  2. run install_yunohostv2 on the raspi
#  3. install an yunohost-firstboot script and shutdown
# 
# Status: functional
# Licence: GPLv3
# Author: sylvain303@github

# wrapper to use ssh with our nopasskey
# Usage: sshpi "some remote commands"
sshpi() {
    ssh -i _build_arm_steps/nopasskey pi@$PI_IP "$@"
}

# harcoded test IP, you can change for yours for debuging. See main()
PI_IP=192.168.1.2
# the installer script is used localy, no git clone else where.
YUNOHOST_INSTALL=../install_yunohostv2
# the folder on the raspberrypi, where script are uploaded
YUNOHOST_REMOTE_DIR=/tmp/install_yunohost
# dummy password
PASSROOT='Free_money?yunomakeit'

# used by main() See at the end.
ask_root_pass() {
    echo "HINT: very good program to generate strong memorisable passwords: pwqgen"
    echo "HINT: sudo apt-get install passwdqc"
    echo -n "Enter a new root password for raspberrypi: "
    read PASSROOT
}

# helper to "scp" a local script to the raspberrypi
# Usage: scp_yunohost local_filename
scp_yunohost() {
    if [[ -z "$1" ]]
    then
        echo "scp_yunohost: expect a local filename"
        return 1
    fi

    if [[ ! -f "$1" ]]
    then
        echo "scp_yunohost: filename not found: '$1'"
        return 1
    fi 

    if [[ -z "$YUNOHOST_REMOTE_DIR" ]]
    then
        echo "scp_yunohost: error \$YUNOHOST_REMOTE_DIR is empty"
        return 1
    fi

    local script="$1"
    local scriptb="$(basename $script)"

    # no real scp, just wrap with sshpi
    cat "$script" | \
    sshpi "mkdir -p $YUNOHOST_REMOTE_DIR && \
        cat > $YUNOHOST_REMOTE_DIR/$scriptb && \
        chmod a+x $YUNOHOST_REMOTE_DIR/$scriptb
        "
}

# helper, compute common remote_step script name so they can be skiped by do_step
make_step_file() {
    local step_name="$1"
    local step_file="yuno_step_${step_name}.sh"
    echo $step_file
}

# helper will create a local script and upload it to raspberrypi in $YUNOHOST_REMOTE_DIR
# Usage: create_remote_script $FUNCNAME "shell commands…"
create_remote_script() {
    local step_file=$(make_step_file "$1")
    local actions="$2"
    local dst="_build_arm_steps/$step_file"

    echo '#!/bin/bash' > $dst
    echo "# $1" >> $dst
    echo "$actions" >> $dst
    scp_yunohost $dst

    # the remote file on the raspi
    echo $YUNOHOST_REMOTE_DIR/$step_file
}

# ======================= ACTIONS - remote actions steps to be performed on the raspberrypi.

init_sdcard_and_reboot() {
    local actions="
# fix locale warning
sudo sed -i -e '/\(en_US\|fr_FR\)\.UTF-8/ s/^# //' /etc/locale.gen
sudo locale-gen
# enlarge filesystem, we need more space to install yunohost
sudo raspi-config --expand-rootfs
echo 'rebooting raspberrypi…'
sudo reboot
"
    create_remote_script $FUNCNAME "$actions"
}

install_yunohostv2_on_sdcard() {
    local actions="
# change root password
echo 'root:$PASSROOT' | sudo chpasswd
# some packages
sudo apt-get -y install git
cat << ENDMSG
!!!!!!!!!!!!!!!!!!!!!!! sdcard builder !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Launching unattended install_yunohostv2 which will take some time to run…
You can watch using a new ssh connection to the raspberrypi.
By example issuing those commands:
 cd $PWD
 source 02_install_yunohost.sh
 sshpi
 tail -f /var/log/yunohost-installation.log
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
ENDMSG
# run yunohost installer unattended (scp previously with scp_yunohost)
cd /tmp/install_yunohost && sudo ./install_yunohostv2 -a
"
    create_remote_script $FUNCNAME "$actions"
}

finalize_yunohost() {
    local actions="
# uploaded modified or new config files to the raspberrypi
cd /
sudo tar xzf $YUNOHOST_REMOTE_DIR/etc.tgz
# yunohost-firstboot is an helper to cleanup and resizefs with srinked sdcard
# image
sudo chmod a+x /etc/init.d/yunohost-firstboot
sudo insserv /etc/init.d/yunohost-firstboot
cat << ENDMSG
=================================================================================
We are going to shutdown the raspberrypi now.
When it's done, the yunohost image is ready to be copied back on your comupter.
* Unplug raspberrypi
* remove the sdcard
* Go to next step!
=================================================================================
ENDMSG
# remove pi user, we will not be able to ssh connect anymore
# sudo userdel pi
sudo shutdown -h now
"
    create_remote_script $FUNCNAME "$actions"
}

reboot_pi() {
    echo "${FUNCNAME}…"
    sshpi "sudo reboot"
}

# ======================= END ACTIONS

# helper, simply visualy wait for raspberrypi to come up for ssh
# Usage: wait_raspberrypi || some_fail command
wait_raspberrypi() {
    local max=30
    local n=1
    local up=false
    while [[ $n -le $max ]]
    do
        sleep 1
        # remove redirect to /dev/null to debug
        output=$(timeout 2 ssh -o "StrictHostKeyChecking=no" \
            -i _build_arm_steps/nopasskey pi@$PI_IP 'echo up' 2> /dev/null)
        echo -n .
        if [[ "$output" == 'up' ]]
        then
            up=true
            break
        fi
        n=$(($n + 1))
    done

    if $up
    then
        echo up
        return 0
    else
        echo too_long
        echo "something goes wrong for your raspberrypi or the timeout it too short"
        echo "please retry"
        return 1
    fi
}

# wrapper, execute a step script on the raspberrypi or skip it
# Status: draft
do_step() {
    local step=$1
    local step_file=$(make_step_file $step)
    local remote_step
    echo -n "$step: "
    # skip if script already there
    if [[ -e "_build_arm_steps/$step_file" ]]
    then
        echo "SKIPED"
        return 1
    else
        echo "RUNING"
        remote_step=$(eval $step)
        sshpi $remote_step
        return 0
    fi
}

# main script code, wrapped inside a function, so the whole script can also be
# sourced as a lib, for debug or unittesting purpose.
main() {
    # you can comment the 2 lines, for debuging. Fix PI_IP with your dhcp IP.
    PI_IP=$1
    ask_root_pass

    do_step init_sdcard_and_reboot

    wait_raspberrypi || return 1

    scp_yunohost $YUNOHOST_INSTALL
    NEED_REBOOT=false
    do_step install_yunohostv2_on_sdcard && { NEED_REBOOT=true; }

    # backup the installation.log on the PC
    sshpi "cat /var/log/yunohost-installation.log" > \
        _build_arm_steps/yunohost-installation.log 

    $NEED_REBOOT && reboot_pi

    wait_raspberrypi || return 1

    # was ./intsall_arm.sh
    tar czf _build_arm_steps/etc.tgz etc
    scp_yunohost _build_arm_steps/etc.tgz
    do_step finalize_yunohost
}

# sourcing code detection, if code is sourced for debug purpose, main is not executed.
[[ $0 != "$BASH_SOURCE" ]] && sourced=1 || sourced=0
if  [[ $sourced -eq 0 ]]
then
    # pass positional argument as is
    main "$@"
fi
