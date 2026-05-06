#!/bin/bash
cd /root/my-bot || exit 1
BEFORE=$(git rev-parse HEAD)
git pull --quiet
AFTER=$(git rev-parse HEAD)
if [ "$BEFORE" != "$AFTER" ]; then
    /root/my-bot/venv/bin/pip install -q -r requirements.txt
    systemctl restart mybot.service
fi
