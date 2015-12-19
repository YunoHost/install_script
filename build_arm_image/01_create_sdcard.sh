#!/bin/bash 
#
# Create the sdcard on your PC with the latest debian.
#
# Usage:
#  ./01_create_sdcard.sh downloaded_debian_image.zip /dev/sdcard_device
#
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
    local out=_build_arm_steps/sha_verify_zip
    skip_if $out && return 2
    sha1sum $zip > $out
    # read only sha check hash
    local sha="$(sed -e 's/\(^[a-f0-9]\+\).*/\1/' $out)"
    if [[ "$sha" != "$SHA_DEBIAN_IMG_ZIP" ]]
    then
        echo "NOK: '$sha' != '$SHA_DEBIAN_IMG_ZIP'"
        exit 1
    fi
}

# unzip raspbian image in the cache folder
unzip_img() {
    if ! skip_if _build_arm_steps/*.img
    then
        unzip -o $DEBIAN_IMG_ZIP -d _build_arm_steps
    fi
    # get extrated image filename from zip file
    DEBIAN_IMG=$(ls _build_arm_steps/ | grep \\.img$)
}

# helper try to guess top device name
# /dev/sdp2 => /dev/sdp
# /dev/mmcblk0p1 => /dev/mmcblk0
# just some regexp no smart thing
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

umount_all_partition() {
    local p
    # search and replace all occurence of / by .
    local pattern=${SDCARD////.}
    pattern=${pattern/p[0-9]/}
    for p in $(df | awk "/^$pattern/ { print \$1 }")
    do
        echo sudo umount $p
    done
    echo "done device for sdcard=${pattern//.//}"
}

dd_to_sdcard() {
    # ensure
    echo dd bs=16M if=_build_arm_steps/$DEBIAN_IMG of=$SDCARD
}

test_all_tools() {
    for t in $*
    do
        test_tool $t
    done
}

# functions call in that order, edit remove a long running step if already done or if
# you want to skip it, step states are saved in folder _build_arm_steps and skipped automatically.
STEPS="
sha_verify_zip 
unzip_img
umount_all_partition
dd_to_sdcard"

# main wrapper, so the script can be sourced for debuging purpose or unittesting
main() {
    # positional argument must be script argument.
    # init
    if [[ -z "$1" ]]
    then
        echo "argument 1 error: expecting raspbian image file.zip"
        echo "can be downloaded here: $DOWNLOAD_URL"
        exit 1
    fi

    # reading script argument
    DEBIAN_IMG_ZIP=$1
    [[ -f "$DEBIAN_IMG_ZIP" ]] || die "error raspbian image not found: '$DEBIAN_IMG_ZIP'"
    SDCARD=$(get_top_device "$2")
    [[ -z "$SDCARD" ]] && die "argument 2 error: expecting sdcard_device"

    test_all_tools dd sync sudo
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
fi
