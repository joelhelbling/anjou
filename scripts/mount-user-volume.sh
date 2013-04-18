#!/bin/sh

DEVICE=$1
USER=$2

# as super user
mke2fs -F -j /dev/$1
mkdir /home/$2
mount /dev/$1 /home/$2
