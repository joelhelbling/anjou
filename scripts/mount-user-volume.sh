
if [ "$1" == "" ]; then

  echo "Usage: mount-user-volume.sh emmajean /dev/sda2"

else

  USER=$1
  # e.g. /dev/sda2
  DEVICE=$( echo $2 | sed -r 's/sda/xvda/' )

  mkdir /home/$USER
  mount $DEVICE /home/$USER

fi

