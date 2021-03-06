require 'asir'

require 'rubygems'
gem 'httpclient'
require 'httpclient'
require 'uri'

module ASIR
  class Transport
    # !SLIDE
    # HTTP Transport
    #
    # Using HTTPClient.
    class HTTP < self
      attr_accessor :uri, :server, :debug

      # Client-side: HTTPClient

      def client
        @client ||=
          Channel.new(:on_connect =>
            lambda { | channel | ::HTTPClient.new })
      end

      def close
        @client.close if @client
      ensure
        @client = nil unless Channel === @client
      end

      # Send the Message payload String using HTTP POST.
      # Returns the HTTPClient::Request response object.
      def _send_message state
        client.with_stream! do | client |
          state.in_stream =
            client.post(message_uri(state), state.message_payload)
        end
      end

      # Subclasses can override.
      def message_uri state
        state.message[:uri] || uri
      end

      # Recieve the Result payload String from the opaque
      # HTTPClient::Request response object returned from #_send_message.
      def _receive_result state
        state.result_payload =
          state.in_stream.content.to_s
      end

      CONTENT_TYPE = 'Content-Type'.freeze
      APPLICATION_BINARY = 'application/binary'.freeze

    end
    # !SLIDE END
  end # class
end # module

