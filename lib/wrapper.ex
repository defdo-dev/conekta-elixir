defmodule Conekta.Wrapper do
    @moduledoc false
    use HTTPoison.Base
    @conekta_accept_header "application/vnd.conekta-v{{version}}+json"

    @config {__MODULE__, :config}

    def put_config(config) when is_map(config)
        and is_map_key(config, :privatekey)
        and is_map_key(config, :locale)
        and is_map_key(config, :apiversion) do
        Process.put(@config, config)
    end

    def get_config(key) do
        Process.get(@config)[key]
    end

    def process_url(url) do
        "https://api.conekta.io/" <> url
    end

    # Transport defaults merged into every request.
    #
    # `pool: false` disables hackney's keepalive connection pool, so each call
    # opens a fresh TCP connection instead of reusing a pooled one.
    #
    # Conekta traffic crosses a NAT gateway that silently drops TCP flows idle
    # for more than ~350s: the flow state is discarded without a FIN/RST, so the
    # local socket still looks established. hackney cannot detect this at
    # checkout -- `hackney_connection:sync_socket/2` only drains messages that
    # have already been delivered (data / closed / error), so a blackholed
    # socket passes the check, gets handed out, and the request then fails with
    # `%HTTPoison.Error{reason: :closed}`.
    #
    # hackney does expose an idle timer for pooled sockets (`hackney_pool`
    # arms `erlang:send_after(Timeout, ...)` on checkin and closes the socket
    # when it fires), and it can be configured per pool. It is not a sufficient
    # guarantee here though: the timer is pool-wide rather than per connection,
    # it races with checkout (both are messages to the same gen_server, so a
    # pending expiry can be processed after the socket has already been handed
    # out), and the stock 150s default -- already well under the ~350s NAT
    # window -- did not prevent the failures we saw in production.
    #
    # Creating an order is a non-idempotent POST, so a transparent retry is not
    # an option and the connection has to be right on the first attempt.
    # Request volume is low (recurring charges run every ~15 min), so the extra
    # TCP + TLS handshake per call is cheap, and it removes dead-socket reuse
    # deterministically rather than probabilistically.
    @hackney_defaults [pool: false]

    def process_request_options(options) do
        hackney = Keyword.merge(@hackney_defaults, Keyword.get(options, :hackney, []))
        Keyword.put(options, :hackney, hackney)
    end

    def process_request_headers(headers) do
        headers ++ headers()
    end

    def headers do
        basic_auth = "Basic " <> Base.encode64(key() <> ":")
        ["Accept": accept_header(), "Accept-Language": locale(), "Content-type": "application/json", "Authorization": basic_auth]
    end

    def accept_header do
        String.replace(@conekta_accept_header, "{{version}}", api_version())
    end

    def key do
        get_config(:privatekey) ||
        Application.get_env(:conekta, :privatekey)
    end

    def locale do
        get_config(:locale) ||
        Application.get_env(:conekta, :locale)
    end

    def api_version do
        get_config(:apiversion) ||
        Application.get_env(:conekta, :apiversion)
    end
end
