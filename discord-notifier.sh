#!/bin/sh
WEBHOOK_URL=""

MESSAGE="${1}"

curl -H "Content-Type: application/json" \
     -X POST \
     -d "$(jq -n --arg msg "$MESSAGE" '{content: $msg}')" \
     "$WEBHOOK_URL"
