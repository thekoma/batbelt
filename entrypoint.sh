#!/bin/bash
echo '<html><head><title>HTTP Hello World</title></head><body><h1>Hello from '$(hostname)'</h1></body></html' > /www/index.html
/usr/bin/python3 -m http.server 8081 --directory /www &
RANDPWD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1)
CREDS="${ADMIN:-admin}:${PASSWORD:-$RANDPWD}"
/usr/bin/ttyd -p 8080 -c "$CREDS" /usr/bin/tmux
