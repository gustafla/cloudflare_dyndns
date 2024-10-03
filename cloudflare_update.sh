#!/bin/bash
set -eu

#https://developers.cloudflare.com/api-next/resources/dns/subresources/records/methods/edit/
api="https://api.cloudflare.com/client/v4/zones"

# $1: Record ID
function record_get {
  curl -sS -X GET -H "Authorization: Bearer $TOKEN" -H "Content-Type:application/json" "$api/$ZONE/dns_records/$1" | jq -r '.result.content'
}

# $1: Record ID, $2: New address
function record_patch {
  curl -sS -X PATCH --data-binary @- -H "Authorization: Bearer $TOKEN" -H "Content-Type:application/json" "$api/$ZONE/dns_records/$1" << 'EOF' | jq -e '.success' >/dev/null || (echo failed; true)
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
addr_ipv4="$(curl -sS -4 https://ident.me)"
rx='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
[[ $addr_ipv4 =~ ^$rx\.$rx\.$rx\.$rx$ ]] && check_and_update "$RECORD_A" "$addr_ipv4" || (echo addr invalid; true)

# IPv6 address (of the $IFACE)
addr_ipv6="$(ip -6 addr list scope global dev $IFACE | grep -oP '(?<=inet6\s)[\da-f:]+' | grep -v "^fd" | head -n 1)"
check_and_update "$RECORD_AAAA" "$addr_ipv6"
