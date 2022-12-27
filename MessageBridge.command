#!/bin/bash
echo -n -e "\033]0;Message Bridge\007"
MBPORT=8080
echo "


Welcome to Message Bridge!

In order to access messages, Message Bridge needs \"Full Disk Access\"
permission granted to it. If you have not yet done so, please follow the
instructions at https://github.com/dremin/message-bridge.
If you have already done this, you can ignore this message!



To access Message Bridge, open a browser to: http://$(ipconfig getifaddr en0):$(echo $MBPORT)


"

cd "`dirname \"$0\"`"
bin/MessageBridge serve --hostname 0.0.0.0 --port $MBPORT
