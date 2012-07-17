require 'asir/transport/delegation'

module ASIR
  class Transport
    # !SLIDE
    # Dynamic Transport
    class Dynamic < self
      include Delegation

      # Proc returning actual transport to use.
      # transport_proc.call(transport, message)
      attr_accessor :transport_proc

      # Only active during #send_message.
      attr_accessor_thread :transport

      # Support for Delegation mixin.
      def transports; [ transport ]; end

      def send_message message
        with_attr! :transport, transport_proc.call(self, message) do
          super
        end
      end

      def _send_message message, message_payload
        # $stderr.puts "  transport = #{transport.inspect}"
        transport.send_message(message)
      end
    end
    # !SLIDE END
  end
end

