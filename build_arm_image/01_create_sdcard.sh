#!/bin/bash 
#
# Create the sdcard on your PC with the latest debian.
#
# Usage:
#  ./01_create_sdcard.sh downloaded_debian_image.zip /dev/sdcard_device
#  ./01_create_sdcard.sh generated_yunohost.img /dev/sdcard_device
#
#
# Status: functional
# Licence: GPLv3
# Author: sylvain303@github

# informations about Raspbian image:
# Raspbian Jessie Lite Version: November 2015 Release date: 2015-11-21
# version: SHA-1 of the .zip: 97888fcd9bfbbae2a359b0f1d199850852bf0104
# Kernel version: 4.1
# http://downloads.raspberrypi.org/raspbian/release_notes.txt

DOWNLOAD_URL=https://www.raspberrypi.org/downloads/raspbian/
SHA_DEBIAN_IMG_ZIP=97888fcd9bfbbae2a359b0f1d199850852bf0104

die() {
    echo "$*"
    exit 1
}

# helper, test if a shell program exists in PATH
test_tool() {
    local cmd=$1
    if type $cmd > /dev/null
    then
        # OK
        return 0
    else
        die "tool missing: $cmd"
    fi
}

# skip if the file exists.
# usage: skip_if _build_arm_steps/somefile && return 2
skip_if() {
    if [[ -e "$1" ]]
    then
        echo "cached"
        return 0
    fi
   # echo -n "continue for $1"
    return 1
}

sha_verify_zip() {
    local zip=$DEBIAN_IMG_ZIP

    [[ -z "$zip" ]] && { echo "no zip refuse to run"; return 3; }

    local out=_build_arm_steps/sha_verify_zip
    skip_if $out && return 2
    sha1sum $zip > $out
    # read only sha check hash
    local sha="$(sed -e 's/\(^[a-f0-9]\+\).*/\1/' $out)"
    if [[ "$sha" != "$SHA_DEBIAN_IMG_ZIP" ]]
    then
        die "NOK: '$sha' != '$SHA_DEBIAN_IMG_ZIP'"
    fi
}

# unzip raspbian image in the cache folder
unzip_img() {
    local img_filename=$(unzip -l $DEBIAN_IMG_ZIP | awk '/\.img$/ { print $4 }')
    if ! skip_if _build_arm_steps/$img_filename
    then
        unzip -o $DEBIAN_IMG_ZIP -d _build_arm_steps
    fi

    # get extrated image filename from zip file
    DEBIAN_IMG="_build_arm_steps/$img_filename"
}

# helper, try to guess top device name
# /dev/sdp2 => /dev/sdp
# /dev/mmcblk0p1 => /dev/mmcblk0
# just some regexp, no smart thing
get_top_device() {
    local device="$1"
    local regexp1='^/dev/sd[a-z]'
    local regexp2='^/dev/mmcblk[0-9]'

    if [[ "$device" =~ $regexp1 ]]
    then
        #echo sd
        device="${device/[0-9]/}"
    elif [[ "$device" =~ $regexp2 ]]
    then
        #echo mmcblk
        device="${device/p[0-9]/}"
    fi

    echo "$device"
}

# helper, umount the sdcard partition if any
umount_sdcard_partition() {
    [[ -z "$SDCARD" ]] && { echo '$SDCARD is empty refusing to run'; return; }
    local p
    # search and replace all occurence of / by .
    local pattern=${SDCARD////.}
    pattern=${pattern/p[0-9]/}
    for p in $(df | awk "/^$pattern/ { print \$1 }")
    do
        sudo umount $p
    done
    echo "done device for sdcard=${pattern//.//}"
}

dd_to_sdcard() {
    [[ -z "$SDCARD" ]] && { echo '$SDCARD is empty refusing to run'; return; }
    # ensure that sdcard partitions are unmounted with umount_sdcard_partition
    echo "starting dd it will take some times…"
    sudo dd bs=16M if="$DEBIAN_IMG" of=$SDCARD
    sudo sync
}

test_all_tools() {
    for t in $*
    do
        test_tool $t
    done
}

# mount the .img so we can write on it before copying on the sdcard
mount_loopback_img() {
    [[ -z "$DEBIAN_IMG" ]] && { echo '$DEBIAN_IMG is empty refusing to run'; return; }
    mkdir -p _build_arm_steps/mnt
    local dev_loop0=$(sudo losetup -f --show "$DEBIAN_IMG")
    local part_offset=$(sudo fdisk -l $dev_loop0 | awk '/Linux/ { print $2 }')
    # mount the ext4 partition at computed offset
    local dev_loop1=$(sudo losetup -f --show -o $((512 * $part_offset)) "$DEBIAN_IMG")
    sudo mount $dev_loop1 _build_arm_steps/mnt/
}

umount_loopback_img() {
    # find mounted loopback
    local dev_loop1=$(mount | awk '/_build_arm_steps/ { print $1 }')
    # compute loop n-1
    local n=${dev_loop1#/dev/loop}
    local dev_loop0="/dev/loop$(($n - 1))"
    sudo umount _build_arm_steps/mnt
    sudo losetup -d $dev_loop1
    sudo losetup -d $dev_loop0
}

# copy a local key for ssh without password later
# having an ssh-key pair to remote connect on the raspi will be used by the next step
add_ssh_key_to_img() {
    mount_loopback_img
    cd _build_arm_steps/mnt/home/pi/
    mkdir .ssh
    local ssh_key=$OLDPWD/_build_arm_steps/nopasskey
    # silently generate an ssh-key pair
    yes | ssh-keygen -q -t rsa -C "nopasskey-install" -N "" -f $ssh_key > /dev/null
    cp ${ssh_key}.pub .ssh/authorized_keys
    # remove some permissions
    chmod -R go= .ssh/
    # give to pi user id
    sudo chown  -R --reference . .ssh
    # return to working folder
    cd - > /dev/null
    umount_loopback_img
    echo "ssh-key added"
}

# functions call in that order, edit remove a long running step if already done or if
# you want to skip it, step states are saved in folder _build_arm_steps and skipped automatically.
# STEPS is modifiy in main() if argument1 is an .img and not a .zip
STEPS="
sha_verify_zip
unzip_img
add_ssh_key_to_img
umount_sdcard_partition
dd_to_sdcard"

# main wrapper, so the script can be sourced for debuging purpose or unittesting
main() {
    # positional argument must be script argument.
    # init
    if [[ -z "$1" ]]
    then
        echo "argument 1 error: expecting raspbian image file.zip or an img"
        echo "can be downloaded here: $DOWNLOAD_URL"
        exit 1
    fi

    local regexp='\.img$'

    # reading script argument
    DEBIAN_IMG_ZIP=$1
    if [[ "$1" =~ $regexp ]]
    then
        DEBIAN_IMG="$1"
        DEBIAN_IMG_ZIP=""
        # write image verbatim without modification
        STEPS="
        umount_sdcard_partition
        dd_to_sdcard"
    else
        [[ -f "$DEBIAN_IMG_ZIP" ]] || die "error raspbian image not found: '$DEBIAN_IMG_ZIP'"
    fi

    SDCARD=$(get_top_device "$2")
    [[ -z "$SDCARD" ]] && die "argument 2 error: expecting sdcard_device"

    test_all_tools dd sync sudo losetup ssh-keygen
    mkdir -p _build_arm_steps

    # actions loop
    for s in $STEPS
    do
        echo -n "$s: "
        eval $s
    done
}

# sourcing code detection, if code is sourced for debug purpose, main is not executed.
[[ $0 != "$BASH_SOURCE" ]] && sourced=1 || sourced=0
if  [[ $sourced -eq 0 ]]
then
    # pass positional argument as is
    main "$@"
else
    # just print STEPS so I can copy/paste to call them interactivly
    echo $STEPS
fi
