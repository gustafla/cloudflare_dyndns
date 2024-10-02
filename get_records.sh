#!/bin/bash
set -eu

api="https://api.cloudflare.com/client/v4/zones"

. .env || true

[[ -z "$TOKEN" ]] && TOKEN="$1"
[[ -z "$ZONE" ]] && ZONE="$2"

result="$(curl -sS -X GET "$api/$ZONE/dns_records" -H "Authorization: Bearer $TOKEN" -H "Content-Type:application/json")"

[[ $(echo "$result" | jq '.success') == "true" ]]

echo "$result" | jq '.result[] | select(.type == "A" or .type == "AAAA")'
