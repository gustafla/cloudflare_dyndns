# Very Dumb Cloudflare Dynamic DNS Client

Do not rely on this script for valuable domains.

## Dependencies

- systemd (you may write your own init scripts if not using systemd)
- bash
- grep
- coreutils
- curl
- jq
- iproute2

## Configuration

0. [Create an API token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)

1. Create all A and AAAA records manually in [Cloudflare dashboard](https://dash.cloudflare.com)

2. Run ./get_records.sh to get the zone and record IDs
```
set +o history
./get_records.sh <your_zone> <your_api_token>
# eg. ./get_records mydomain.com tokentoken1234
set -o history
```

3. Create configuration directory and files

`mkdir /etc/cloudflare_dyndns`

`/etc/cloudflare_dyndns/<mydomain-com>`
```
TOKEN=<your_api_token>
IFACE=<your_network_interface_for_mydomain_com>
ZONE=<zone_id>
RECORDS_A=<a_record_id>
RECORDS_AAAA=<aaaa_record_id>
```

Remember to protect your secrets:
```
chmod 700 /etc/cloudflare_dyndns
chmod 600 /etc/cloudflare_dyndns/*
```

## Installation

First install dependencies where this will run, then copy or symlink the files

```
ln -s $PWD/cloudflare-dyndns@.service /etc/systemd/system/cloudflare-dyndns@.service 
ln -s $PWD/cloudflare-dyndns@.timer /etc/systemd/system/cloudflare-dyndns@.timer 
ln -s $PWD/cloudflare_dyndns.sh /usr/local/bin/cloudflare_dyndns.sh
```

Finally start (and enable) the timer

```
systemctl enable --now cloudflare-dyndns@mydomain-com.timer
```

## Example

Let's say you want to set the same addresses to
`mydomain.com` and `www.mydomain.com`.
First you run `./get_records.sh mydomain.com <your_api_token>`
and get the following:
```
Zone ID: zzzzz
{
  "id": "aaaaa",
  "name": "www.mydomain.com",
  "type": "A"
}
{
  "id": "bbbbb",
  "name": "www.mydomain.com",
  "type": "AAAA"
}
{
  "id": "ccccc",
  "name": "mydomain.com",
  "type": "A"
}
{
  "id": "ddddd",
  "name": "mydomain.com",
  "type": "AAAA"
}
```

Then you create a configuration file on the host with the address you want:

`/etc/cloudflare_dyndns/mydomain-com`
```
TOKEN=<your_api_token>
ZONE=zzzzz
IFACE=enp1s0
RECORDS_A=aaaaa ccccc
RECORDS_AAAA=bbbbb ddddd
```

Remember to protect your secrets:
```
chmod 700 /etc/cloudflare_dyndns
chmod 600 /etc/cloudflare_dyndns/*
```

Finally you start the timer template for the configuration file instance

```
systemctl enable --now cloudflare-dyndns@mydomain-com.timer
```

Check that the timers and services are working:
```
systemctl list-timers
systemctl status cloudflare-dyndns@mydomain-com.service
```
