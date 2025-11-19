#!/bin/bash

sleep 4
mac=`/usr/bin/perl /etc/transit-appliance/mac.pl`

/etc/transit-appliance/oshealth.pl --startup

#echo "the value is $mac"

counter=1
while [ $counter -le 2 ]
do
 ((counter++))
 /usr/bin/chromium file:///etc/transit-appliance/jsconfig/loadappliance.html \
    --no-message-box \
    --no-first-run \
    --disable-restore-session-state \
    --disable-breakpad \
    --disable-desktop-notifications \
    --kiosk --ozone-platform=wayland --start-maximized --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar \
    --disable-gpu \
    --disk-cache-dir=/tmp \
    --window-position=0,0 \
    --start-fullscreen \
    --incognito \
    --noerrdialogs \
    --disable-translate \
    --no-first-run \
    --fast \
    --fast-start \
    --disable-infobars \
    --disable-features=TranslateUI \
    --overscroll-history-navigation=0 \
    --disable-pinch
done

