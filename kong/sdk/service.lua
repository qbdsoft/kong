local balancer = require "kong.runloop.balancer"
local phase_checker = require "kong.sdk.private.phases"


local ngx = ngx
local check_phase = phase_checker.check


local PHASES = phase_checker.phases


local function new()
  local service = {}


  ------------------------------------------------------------------------------
  -- Sets the Upstream object to be used by the service to which
  -- Kong will proxy the request.
  -- The `Host` header is not set: use
  -- `kong.service.request.set_header` to set the header.
  --
  -- @param host Host name to set. Example: "example.com"
  -- @return `true` on success, `nil` and an error message if the
  -- upstream name is invalid; throws an error on malformed inputs.
  function service.set_upstream(host)
    check_phase(PHASES.access)

    if type(host) ~= "string" then
      error("host must be a string", 2)
    end

    local upstream = balancer.get_upstream_by_name(host)
    if not upstream then
      return nil, "could not find an Upstream named '" .. host .. "'"
    end

    ngx.ctx.balancer_address.host = host
    return true
  end


  ------------------------------------------------------------------------------
  -- Sets the target host and port for the service to which Kong will
  -- proxy the request. The `Host` header is not set: use
  -- `kong.service.request.set_header` to set the header.
  --
  -- @param host Host name to set. Example: "example.com"
  -- @param port A port number between 0 and 65535.
  -- @return Nothing; throws an error on malformed inputs.
  function service.set_target(host, port)
    check_phase(PHASES.access)

    if type(host) ~= "string" then
      error("host must be a string", 2)
    end
    if type(port) ~= "number" or math.floor(port) ~= port then
      error("port must be an integer", 2)
    end
    if port < 0 or port > 65535 then
      error("port must be an integer between 0 and 65535: given " .. port, 2)
    end

    ngx.var.upstream_host = host
    ngx.ctx.balancer_address.host = host
    ngx.ctx.balancer_address.port = port
  end


  ------------------------------------------------------------------------------
  -- Determine if the request was proxied by to a service
  -- or if the response was produced by Kong itself.
  --
  -- @return true if the request was proxied by Kong;
  function service.was_proxied()
    check_phase(PHASES.request)

    return ngx.ctx.KONG_PROXIED == true
  end


  return service
end


return {
  new = new,
}