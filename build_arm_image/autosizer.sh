#!/bin/bash
# Automatic Image file resizer
# Written by SirLagz
#
# got from: http://sirlagz.net/2013/03/10/script-automatic-rpi-image-downsizer/
#
# Usage: sudo autosizer.sh sdcard.img

strImgFile=$1

if [[ ! $(whoami) =~ "root" ]]; then
    echo ""
    echo "**********************************"
    echo "*** This should be run as root ***"
    echo "**********************************"
    echo ""
    exit
fi

if [[ -z $strImgFile ]]; then
    echo "Usage: ./autosizer.sh <Image File>"
    exit
fi

if [[ ! -e $strImgFile || ! $(file $strImgFile) =~ "x86" ]]; then
    echo "Error : Not an image file, or file doesn't exist"
    exit
fi

partinfo=`parted -m $strImgFile unit B print`
partnumber=`echo "$partinfo" | grep ext4 | awk -F: ' { print $strImgFile } '`
partstart=`echo "$partinfo" | grep ext4 | awk -F: ' { print substr($2,0,length($2)-1) } '`
loopback=`losetup -f --show -o $partstart $strImgFile`
e2fsck -f $loopback
minsize=`resize2fs -P $loopback | awk -F': ' ' { print $2 } '`
minsize=`echo $minsize+1000 | bc`
resize2fs -p $loopback $minsize
sleep 1
losetup -d $loopback
partnewsize=`echo "$minsize * 4096" | bc`
newpartend=`echo "$partstart + $partnewsize" | bc`
# TODO: 2 is probably $partnumber
part1=`parted $strImgFile rm 2`
part2=`parted $strImgFile unit B mkpart primary $partstart $newpartend`
endresult=`parted -m $strImgFile unit B print free | tail -1 | awk -F: ' { print substr($2,0,length($2)-1) } '`
truncate -s $endresult $strImgFile
