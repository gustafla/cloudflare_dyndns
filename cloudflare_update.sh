#!/bin/bash
set -eu

#https://developers.cloudflare.com/api-next/resources/dns/subresources/records/methods/edit/
api="https://api.cloudflare.com/client/v4/zones"

ident_a_addr="$(curl -sS -4 https://ident.me)"
echo cur $ident_a_addr
rx='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
[[ $ident_a_addr =~ ^$rx\.$rx\.$rx\.$rx$ ]] || (echo addr invalid; exit 1)
ip_aaaa_addr="$(ip -6 addr list scope global dev $IFACE | grep -oP '(?<=inet6\s)[\da-f:]+' | grep -v "^fd" | head -n 1)"
echo cur $ip_aaaa_addr

dns=($NS)
dns_server=${dns[$RANDOM % ${#dns[@]}]}
echo sending dns queries to $dns_server

#TODO replace dig with Cloudflare API
dns_a_record="$(dig +short @$dns_server $zone A)"
echo dns $dns_a_record \($zone\)
if [[ "$dns_a_record" != "$ident_a_addr" ]]; then
  echo updating
  #curl -4sS "https://dynv6.com/api/update?zone=$zone&token=$TOKEN&ipv4=$ident_a_addr"
  curl -sS -X PATCH --data-binary @- -H "Authorization: Bearer $TOKEN" -H "Content-Type:application/json" "$api/$ZONE/dns_records/$RECORD_A" <<EOF
{
  "content": "$ident_a_addr"
}
EOF
else
  echo no action
fi

#TODO replace dig with Cloudflare API
dns_aaaa_record="$(dig +short @$dns_server $zone AAAA)"
echo dns $dns_aaaa_record \($zone\)
if [[ "$dns_aaaa_record" != "$ip_aaaa_addr" ]]; then
  echo updating
  #curl -sS "https://dynv6.com/api/update?zone=$zone&token=$TOKEN&ipv6prefix=auto&ipv6=$ip_aaaa_addr"
else
  echo no action
fi
