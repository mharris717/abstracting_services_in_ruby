require 'asir/transport'
require 'thread'

module ASIR
  class Transport
    # !SLIDE
    # Buffer Transport
    #
    # Buffers Requests until #flush!
    # Assumes One-way Requests.
    class Buffer < self
      include Delegation

      # Transport to send_request.
      attr_accessor :transport

      def initialize *args
        super
        @requests = [ ]
        @requests_mutex = Mutex.new
        @paused = 0
        @paused_mutex = Mutex.new
      end

      # If paused, queue requests,
      # Otherwise delegate immediately to #transport.
      def _send_request request, request_payload
        if paused?
          @requests_mutex.synchronize do
            @requests << request
          end
          nil
        else
          @transport.send_request(request)
        end
      end

      # Returns true if currently paused.
      # Requests are queued until #resume!.
      def paused?
        @paused > 0
      end

      # Pauses all requests until resume!.
      # May be called multiple times.
      def pause!
        @paused_mutex.synchronize do
          @paused += 1
        end
        self
      end

      # Will automatically call #flush! when not #paused?.
      def resume!
        should_flush = @paused_mutex.synchronize do
          @paused -= 1 if @paused > 0
          @paused == 0
        end
        flush! if should_flush
        self
      end

      def size
        @requests_mutex.synchronize do
          @requests.size
        end
      end

      # Will flush pending Requests even if ! #paused?.
      def flush!
        clear!.each do | request |
          @transport.send_request(request)
        end
        self
      end

      # Clear all pending Requests without sending them.
      # Returns requests that would have been sent.
      def clear!
        requests = nil
        @requests_mutex.synchronize do
          requests = @requests
          @requests = [ ]
        end
        requests
      end
    end
    # !SLIDE END
  end
end
