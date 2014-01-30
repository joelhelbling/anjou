#!/bin/sh

apt-get -q -y install tmux
git clone git://github.com/zolrath/wemux.git /usr/local/share/wemux
ln -s /usr/local/share/wemux/wemux /usr/local/bin/wemux
cp /usr/local/share/wemux/wemux.conf.example /usr/local/etc/wemux.conf

# need a way to add participants as hosts...
sed -i 's/host_list=(change_this)/host_list=(joelhelbling ubuntu anjouhost)/g' /usr/local/etc/wemux.conf

wemux start
chmod 1777 /tmp/wemux-wemux

