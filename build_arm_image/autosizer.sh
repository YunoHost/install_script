#!/bin/bash
# Automatic Image file resizer
# Written by SirLagz
strImgFile=$1

if [[ ! $(whoami) =~ "root" ]]; then
    echo ""
    echo "**********************************"
    echo "*** This should be run as root ***"
    echo "**********************************"
    echo ""
    exit
fi

if [[ -z $1 ]]; then
    echo "Usage: ./autosizer.sh <Image File>"
    exit
fi

if [[ ! -e $1 || ! $(file $1) =~ "x86" ]]; then
    echo "Error : Not an image file, or file doesn't exist"
    exit
fi

partinfo=`parted -m $1 unit B print`
partnumber=`echo "$partinfo" | grep ext4 | awk -F: ' { print $1 } '`
partstart=`echo "$partinfo" | grep ext4 | awk -F: ' { print substr($2,0,length($2)-1) } '`
loopback=`losetup -f --show -o $partstart $1`
e2fsck -f $loopback
minsize=`resize2fs -P $loopback | awk -F': ' ' { print $2 } '`
minsize=`echo $minsize+1000 | bc`
resize2fs -p $loopback $minsize
sleep 1
losetup -d $loopback
partnewsize=`echo "$minsize * 4096" | bc`
newpartend=`echo "$partstart + $partnewsize" | bc`
part1=`parted $1 rm 2`
part2=`parted $1 unit B mkpart primary $partstart $newpartend`
endresult=`parted -m $1 unit B print free | tail -1 | awk -F: ' { print substr($2,0,length($2)-1) } '`
truncate -s $endresult $1
