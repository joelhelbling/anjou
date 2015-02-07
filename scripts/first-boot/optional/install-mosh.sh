#!/bin/sh

apt-get -q -y install python-software-properties
add-apt-repository -y ppa:keithw/mosh
apt-get -q -y install mosh
