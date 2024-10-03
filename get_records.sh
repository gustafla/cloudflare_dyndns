#!/bin/bash
set -eu

api="https://api.cloudflare.com/client/v4/zones"

. .env || true

if [[ -z "$TOKEN" ]]; then
  if [[ -z "$2" ]]; then
    echo Provide TOKEN either in .env or as the second cli parameter
    exit 1
  fi
  TOKEN="$2"
fi
[[ -z "$1" ]] && (echo Provide zone as CLI parameter; exit 1)

auth="Authorization: Bearer $TOKEN"
content_type="Content-Type: application/json"

zone=$(curl -sS -H "$auth" -H "$content_type" "$api" | \
  jq -er ".result[] | select(.name == \"$1\") | .id")
echo Zone ID: $zone

curl -sS -H "$auth" -H "$content_type" "$api/$zone/dns_records" | \
  jq -e '.result[] | select(.type == "A" or .type == "AAAA") | {id, name, type}'
