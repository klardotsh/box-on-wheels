#!/bin/sh

betterdiscordctl install
# `which discord` provided an sbin path in the container, which blows my mind
/usr/sbin/discord $@
