#!/bin/bash
#
# Usage: ./02_install_yunohost.sh DHCP_IP_ADDRESS_OF_RASPBERRYPI
#
# apply this doc: https://github.com/Sylvain304/doc/blob/master/build_arm_image.md
# 
# Status: draft
# Licence: GPLv3
# Author: sylvain303@github

# usefull wrapper to use ssh with our nopasskey
sshpi() {
    ssh -i _build_arm_steps/nopasskey pi@$PI_IP "$@"
}

# harcoded test IP
PI_IP=192.168.1.50
YUNOHOST_INSTALL=../install_yunohostv2
YUNOHOST_REMOTE_DIR=/tmp/install_yunohost

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

    local script=$1
    local scriptb=$(basename $script)

    cat "$script" | \
    sshpi "mkdir -p $YUNOHOST_REMOTE_DIR && \
        cat > $YUNOHOST_REMOTE_DIR/$scriptb && \
        chmod a+x $YUNOHOST_REMOTE_DIR/$scriptb
        "
}

# helper, compute common remote_step script name so they can be skiped by do_step
make_step_file() {
    local step_name="$1"
    local step_file=yuno_step_${step_name}.sh
    echo $step_file
}

# helper will create a local script and upload it to raspberrypi in $YUNOHOST_REMOTE_DIR
# Usage: create_remote_script $FUNCNAME "shell commands…"
create_remote_script() {
    local step_file=$(make_step_file "$1")
    local actions="$2"

    echo '#!/bin/bash' > _build_arm_steps/$step_file
    echo "$actions" >> _build_arm_steps/$step_file
    scp_yunohost _build_arm_steps/$step_file

    echo $YUNOHOST_REMOTE_DIR/$step_file
}

init_sdcard_and_reboot() {
    local actions="
# fix locale warning
sudo sed -i -e '/\(en_US\|fr_FR\)\.UTF-8/ s/^# //' /etc/locale.gen
sudo locale-gen
# enlarge filesystem, we need more space to install yunohost
sudo raspi-config --expand-rootfs
sudo reboot
"
    create_remote_script $FUNCNAME "$actions"
}

install_yunohostv2_on_sdcard() {
    local actions="
# change root password
echo 'root:$PASSROOT' | sudo chpasswd
sudo apt-get -y install git
# so you can hack your local copy of install_yunohost over and over…
# run yunohost installer unattended (scp previously with scp_yunohost_installer)
cat << ENDMSG
Launching unattended install_yunohostv2 which will take some time to run…
You can watch using a new ssh connection to the raspberrypi.
By example issuing those commands:
 cd $PWD
 source 02_install_yunohost.sh
 sshpi
 tail -f /var/log/yunohost-installation.log
ENDMSG
cd /tmp/install_yunohost && sudo ./install_yunohostv2 -a
"
    create_remote_script $FUNCNAME "$actions"
}

finalize_yunohost() {
    local actions="
cd /
tar xzf $YUNOHOST_REMOTE_DIR/etc.tzg
chmod a+x /etc/init.d/yunohost-firstboot
insserv /etc/init.d/yunohost-firstboot
cat << ENDMSG
We are going to shutdown the raspberrypi now.
When it's done, the yunohost image is ready to be copied back on your comupter.
* Unplug raspberrypi
* remove the sdcard
* Go to next step
ENDMSG
shutdown
"
    create_remote_script $FUNCNAME "$actions"
}

reboot_pi() {
    echo "${FUNCNAME}…"
    sshpi "sudo reboot"
}

# helper simply visualy wait for raspberrypi to come up for ssh
wait_raspberrypi() {
    local max=30
    local n=1
    local up=false
    while [[ $n -le $max ]]
    do
        sleep 1
        output=$(timeout 2 ssh -i _build_arm_steps/nopasskey pi@$PI_IP 'echo up' 2> /dev/null)
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

do_step() {
    local step=$1
    local step_file=$(make_step_file $step)
    local remote_step
    echo -n "$step: "
    if [[ -e "_build_arm_steps/$step_file" ]]
    then
        echo "SKIPED"
    else
        echo "RUNING"
        remote_step=$(eval $step)
        sshpi $remote_step
    fi
}

main() {
    do_step init_sdcard_and_reboot

    wait_raspberrypi || return 1

    do_step install_yunohostv2_on_sdcard

    # copy the installation.log on the PC
    sshpi "cat /var/log/yunohost-installation.log" > \
        _build_arm_steps/yunohost-installation.log 

    reboot_pi

    wait_raspberrypi || return 1

    # was ./intsall_arm.sh
    tar czf _build_arm_steps/etc.tgz etc
    scp_yunohost _build_arm_steps/etc.tgz
    do_step finalize_yunohost
}
