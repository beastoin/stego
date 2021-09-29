vcl 4.1;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "127.0.0.1";
    .port = "80";
}

sub vcl_recv {
    # shipapi, local.api.loship ~ nginx proxy pass
    if (req.http.host == "local.api.loship") {
        return (vcl(label-mocha-local));
    }
    # varnish admin mocha, local.cache.loship ~ nginx proxy pass
    if (req.http.host == "local.cache.loship") {
        return (vcl(label-mocha-local));
    }
    
    return (synth(404));
}
