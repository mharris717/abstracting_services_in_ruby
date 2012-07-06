require 'asir'
require 'uri'

module ASIR
  module UriConfig
    attr_accessor :uri, :scheme, :host, :port
    attr_accessor :scheme_default, :host_default, :port_default
    alias :protocol :scheme
    alias :protocol= :scheme=
    alias :address :host
    alias :address= :host=

    def uri
      @uri ||= "#{scheme}://#{host}:#{port}"
    end

    def _uri
      @_uri ||=
        URI === @uri ? @uri : URI.parse(uri)
    end

    def scheme
      @scheme ||=
        (@uri && _uri.scheme) ||
        @scheme_default ||
        S_TCP
    end
    S_TCP = 'tcp'.freeze

    def host
      @host ||=
        (@uri && _uri.host) ||
        @host_default ||
        S_LOCALHOST
    end
    S_LOCALHOST = '127.0.0.1'.freeze

    def port
      @port ||=
        (@uri && _uri.port) ||
        @port_default ||
        (raise Error, "#{self.class}: port not set.")
    end

  end
end
