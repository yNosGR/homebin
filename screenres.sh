#!/bin/sh
xrandr --output DP3 --off --output eDP1 --mode 1920x1080 --pos 0x0 --rotate normal --output DP1 --off --output DP2 --off --output HDMI3 --mode 1920x1080 --pos 1920x0 --rotate normal --output HDMI2 --off --output HDMI1 --off --output VGA1 --off
~/bin/resyn
