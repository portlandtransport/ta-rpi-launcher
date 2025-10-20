#!/bin/bash

mac=`/usr/bin/perl /transit-appliance/mac.pl`

#echo "the value is $mac"

while true; do
 /usr/bin/chromium-browser file:///transit-appliance/jsconfig/loadappliance.html \
    --no-message-box \
    --no-first-run \
    --disable-restore-session-state \
    --disable-breakpad \
    --disable-desktop-notifications \
    --kiosk \
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

