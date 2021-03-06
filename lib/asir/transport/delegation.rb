module ASIR
  class Transport
    # !SLIDE
    # A Transport that delgated to one or more other Transports.
    #
    # Classes that include this must define #_send_message(message, message_payload).
    module Delegation
      # If true, reraise the first Exception that occurred during Transport#send_message.
      attr_accessor :reraise_first_exception

      # Proc to call(transport, message, exc) when a delegated #send_message fails.
      attr_accessor :on_send_message_exception

      # Proc to call(transport, message) when #send_message fails with no recourse.
      attr_accessor :on_failed_message

      # Return the subTransports' result unmodified from #_send_message.
      def _receive_result state
        true
      end

      def needs_message_identifier? message
        @needs_message_identifier ||
          transports.any? { | t | t.needs_message_identifier?(message) }
      end

      def needs_message_timestamp? message
        @needs_message_timestamp ||
          transports.any? { | t | t.needs_message_timestamp?(message) }
      end

      # Subclasses with multiple transports should override this method.
      def transports
        @transports ||= [ transport ]
      end

      # Called from within _send_message rescue.
      def _handle_send_message_exception! transport, state, exc
        _log { [ :send_message, :transport_failed, exc, exc.backtrace ] }
        (state.message[:transport_exceptions] ||= [ ]) << "#{exc.inspect}: #{exc.backtrace.first}"
        @on_send_message_exception.call(self, state, exc) if @on_send_message_exception
        self
      end
    end
    # !SLIDE END
  end
end

