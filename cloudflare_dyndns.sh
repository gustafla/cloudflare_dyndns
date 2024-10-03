#!/bin/bash
set -e

[[ -z "$TOKEN" ]] && (echo "TOKEN not defined, check configuration"; exit 1)
[[ -z "$ZONE" ]] && (echo "ZONE not defined, check configuration"; exit 1)

#https://developers.cloudflare.com/api-next/resources/dns/subresources/records/methods/edit/
api="https://api.cloudflare.com/client/v4/zones"
ident="https://ident.me"
auth="Authorization: Bearer $TOKEN"
content_type="Content-Type: application/json"

# $1: Record ID
function record_get {
  curl -sS -X GET -H "$auth" -H "$content_type" "$api/$ZONE/dns_records/$1" | jq -er '.result.content'
}

# $1: Record ID, $2: New address
function record_patch {
  curl -sS -X PATCH --data-binary @- -H "$auth" -H "$content_type" "$api/$ZONE/dns_records/$1" << 'EOF' | jq -e '.success' >/dev/null || (echo failed; true)
{"content":"$2"}
EOF
}

# $1: Record ID, $2: My address
function check_and_update {
  record="$(record_get $1)"
  echo new "$2"
  echo old "$record"
  if [[ "$record" != "$2" ]]; then
    echo updating
    record_patch "$1" "$2"
  else
    echo no action
  fi
}

# IPv4 address (behind NAT)
if [[ -z "$RECORDS_A" ]]; then
  echo "RECORDS_A undefined, skipping IPv4"
else
  addr_ipv4="$(curl -sS -4 "$ident")"
  rx='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
  if [[ $addr_ipv4 =~ ^$rx\.$rx\.$rx\.$rx$ ]]; then
    for record in $RECORDS_A; do
      check_and_update "$record" "$addr_ipv4"
    done
  else
    echo "Invalid response from $ident"
  fi
fi

# IPv6 address (of the $IFACE)
if [[ -z "$RECORDS_AAAA" ]]; then
  echo "RECORDS_AAAA undefined, skipping IPv6"
else
  [[ -z "$IFACE" ]] && (echo "IFACE not defined, check configuration"; exit 1)
  addr_ipv6="$(ip -6 addr list scope global dev $IFACE | grep -oP '(?<=inet6\s)[\da-f:]+' | grep -v "^fd" | head -n 1)"
  for record in $RECORDS_AAAA; do
    check_and_update "$record" "$addr_ipv6"
  done
fi
