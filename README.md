# Very Dumb Cloudflare Dynamic DNS Client

Do not rely on this script for valuable domains.

## Dependencies:

- systemd (you may write your own init scripts if not using systemd)
- bash
- curl
- jq
- iproute2

## Configuration:

0. [Create an API token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)

1. Create all A and AAAA records manually in [Cloudflare dashboard](https://dash.cloudflare.com)

2. Run ./get_records.sh to get the zone and record IDs
```
set +o history
./get_records.sh <your_zone> <your_api_token>
# eg. ./get_records mydomain.com tokentoken1234
set -o history
```

3. Create configuration files and directories

`mkdir /etc/cloudflare_dyndns.d`

`/etc/cloudflare_dyndns.conf`
```
TOKEN=<your_api_token>
```

`/etc/cloudflare_dyndns.d/<mydomain-com>`
```
IFACE=<your_network_interface_for_mydomain_com>
ZONE=<zone_id>
RECORD_A=<a_record_id>
RECORD_AAAA=<aaaa_record_id>
```

Remember to protect your secrets:
```
chmod 700 /etc/cloudflare_dyndns.d
chmod 600 /etc/cloudflare_dyndns.d/* /etc/cloudflare_dyndns.conf
```

## Installation:

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
