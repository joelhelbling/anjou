#!/bin/sh

sudo apt-get install tmux
sudo git clone git://github.com/zolrath/wemux.git /usr/local/share/wemux
sudo ln -s /usr/local/share/wemux/wemux /usr/local/bin/wemux
sudo cp /usr/local/share/wemux/wemux.conf.example /usr/local/etc/wemux.conf

sudo sed -i 's/host_list=(change_this)/host_list=(joelhelbling ubuntu)/g' /usr/local/etc/wemux.conf

# need a way to add participants as hosts...

sudo wemux start
sudo chmod 1777 /tmp/wemux-wemux

