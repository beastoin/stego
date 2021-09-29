# Stego: Sidecar caching
A powerfull, painless, flexible caching.

## Prerequisites (2)
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
 - Host admin (Using to reload site configs): `local.cache.loship`
 - Label (From 2.): `label-mocha-local`

4. Run by command from .service
 ```
 <path-to-varnishd> \
          -I varnish.cli \
          -a :6081 \
          -a localhost:8444,PROXY \
          -p feature=+http2 \
          -f '' \
          -s malloc,256m
 ```

## Features
- Caching target sites by multiple host.
- Update / Reload routes, ttls.

## TODOs
- Add autogen target sites 
