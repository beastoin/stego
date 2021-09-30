#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide for a comprehensive documentation
# at https://www.varnish-cache.org/docs/.

# Marker to tell the VCL compiler that this VCL has been written with the
# 4.0 or 4.1 syntax.
vcl 4.1;
import std;
import cfg;


# Default backend definition. Set this to point to your content server.
backend mocha-api-local {
    .host = "127.0.0.1";
    .port = "11001";
}

sub vcl_init {
    # lua func (1)
    new get_hash_func = cfg.script(
        "/dev/null",
        period=0,
        type=lua,
        lua_remove_loadfile_function=false,
        lua_load_package_lib=true,
        lua_load_io_lib=true,
        lua_load_os_lib=true);

    # headers rules
    new headers = cfg.rules(
        "file:///etc/varnish/mocha.headers.rules",
        period=300);

    # ttls rules
    new ttls = cfg.rules(
        "file:///etc/varnish/mocha.ttls.rules",
        period=300);
}

acl internal {
    "localhost";
    "172.16.10.112";
}

sub vcl_recv {
    # varnish settings reload
    # WARN: internal acl may be passed over incase varnish server is the same to reverse proxy server
    if (client.ip ~ internal && req.method == "PURGE") {
        if (req.url == "/varnish/settings/lSRIII6jn16TcghWv5r6FW0DIua2Obzl/reload") {
                if (headers.reload()) {
                    return (synth(200, "Headers reloaded."));
                } else {
                    return (synth(500, "Failed to reload headers."));
                }
            } elsif (req.url == "/varnish/settings/S4p3c4XCzf1QvW75xRWCoMwNJmxSvJd3/reload") {
                if (ttls.reload()) {
                    return (synth(200, "TTLs rules reloaded."));
                } else {
                    return (synth(500, "Failed to reload TTLs rules."));
                }
            }
    }

    # Validate headers
    if (req.method != "GET" &&
        req.method != "HEAD" &&
        req.method != "PUT" &&
        req.method != "POST" &&
        req.method != "TRACE" &&
        req.method != "OPTIONS" &&
        req.method != "PATCH" &&
        req.method != "DELETE") {
      /* Non-RFC2616 or CONNECT which is weird. */
      return (pipe);
    }

    # Only cache GET or HEAD requests. This makes sure the POST requests are always passed.
    if (req.method != "GET" && req.method != "HEAD") {
      return (pass);
    }

    # not cache incase not set rules
    if (headers.get(req.url) == "") {
	return (pass);
    }

    # Normalize the query arguments
    set req.url = std.querysort(req.url);

    # Set backend
    set req.backend_hint = mocha-api-local;
    return (hash);
}

sub vcl_backend_response {
    # Don't cache 50x responses
    if (beresp.status == 500 || beresp.status == 502 || beresp.status == 503 || beresp.status == 504) {
      return (abandon);
    }

    # ttls
    set beresp.ttl = std.duration(
	ttls.get(bereq.url), 30s
    );

    return (deliver);
}

sub vcl_deliver {
    # by pass cors
    set resp.http.access-control-allow-origin = req.http.Orign;

    # need set x-lozi-server-time header
    set resp.http.X-Lozi-Server-Time = std.time2integer(now, 0);

    # unset headers
    unset resp.http.X-Varnish;
    unset resp.http.Via;
    unset resp.http.Age;
    unset resp.http.Accept-Ranges;
}

sub vcl_hash {
    # hash
    if (headers.get(req.url) != "") {
	get_hash_func.init({"
	    local headers = ARGV[0]
	    local hash = ''
	    for key in string.gmatch(headers, '([^,]+)') do
	    	local value = varnish.get_header(key, 'req')
	    	local headerHash = key .. '='
	    	if value ~= nil then
	            headerHash = headerHash .. tostring(value)
	    	else 
		    headerHash = headerHash .. 'nil'
	    	end
	    	if hash ~= '' then
		    hash = hash .. '&'
	    	end
	    	hash = hash .. headerHash
	    end
	    return hash
	"});
	get_hash_func.push(headers.get(req.url));
	get_hash_func.execute();
	hash_data(get_hash_func.get_result());
	get_hash_func.free_result();
    }
}
