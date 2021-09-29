# Stego: Sidecar caching
A powerfull, painless, flexible caching.

## Prerequisites
  - Varnish https://varnish-cache.org/
  - libvmod-cfg: https://github.com/carlosabalde/libvmod-cfg

## Usage
1. Prepare caching sites
 - Headers rules: `mocha.headers.rules`
 - Ttls rules: `mocha.ttl.rules`
 - Vcl: `mocha.vcl`

2. Load caching sites by update cli `varnish.cli`
 - Load vcl `vcl.load vcl-mocha-local /etc/varnish/mocha.vcl`
 - Load label `vcl.label label-mocha-local vcl-mocha-local`

3. Add caching sites to root `varnish.vcl`
 - Host: `local.api.loship`
 - Label (From 2.): `label-mocha-local`

4. Run by command from .service
 ```
 <path-to-varnishd> \
	  -I /etc/varnish/varnish.cli \
          -a :16081 \
          -p feature=+http2 \
          -f '' \
          -s malloc,1024m
 ```

## Features
- Caching target sites by multiple host.
- Update / Reload routes, ttls. e.g.
 ```
 curl -X PURGE 'https://local.api.loship/varnish/settings/lSRIII6jn16TcghWv5r6FW0DIua2Obzl/reload'
 ```

## TODOs
- Add autogen target sites 
