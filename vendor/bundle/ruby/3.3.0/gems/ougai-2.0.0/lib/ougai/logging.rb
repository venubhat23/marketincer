# frozen_string_literal: true

module Ougai
  # Common Logging features
  module Logging
    attr_accessor :with_fields
    attr_writer :before_log

    module Severity
      include ::Logger::Severity
      TRACE = -1

      SEV_LABEL = %w(TRACE DEBUG INFO WARN ERROR FATAL UNKNOWN)

      def to_label(severity)
        SEV_LABEL[severity + 1] || 'ANY'
      end

      def from_label(severity)
        SEV_LABEL.index(severity) - 1
      rescue
        raise ArgumentError, "invalid log level: #{severity}"
      end
    end
    include Severity

    # Log any one or more of a message, an exception and structured data as TRACE.
    # @return [Boolean] true
    # @see Logging#debug
    def trace(message = nil, ex = nil, data = nil, &block)
      _log(TRACE, message, ex, data, &block)
    end

    # Log any one or more of a message, an exception and structured data as DEBUG.
    # If the block is given for delay evaluation, it returns them as an array or the one of them as a value.
    # @param message [String] The message to log. Use default_message if not specified.
    # @param ex [Exception] The exception or the error
    # @param data [Object] Any structured data
    # @yieldreturn [String|Exception|Object|Array] Any one or more of former parameters
    # @return [Boolean] true
    def debug(message = nil, ex = nil, data = nil, &block)
      _log(DEBUG, message, ex, data, &block)
    end

    # Log any one or more of a message, an exception and structured data as INFO.
    # @return [Boolean] true
    # @see Logging#debug
    def info(message = nil, ex = nil, data = nil, &block)
      _log(INFO, message, ex, data, &block)
    end

    # Log any one or more of a message, an exception and structured data as WARN.
    # @return [Boolean] true
    # @see Logging#debug
    def warn(message = nil, ex = nil, data = nil, &block)
      _log(WARN, message, ex, data, &block)
    end

    # Log any one or more of a message, an exception and structured data as ERROR.
    # @return [Boolean] true
    # @see Logging#debug
    def error(message = nil, ex = nil, data = nil, &block)
      _log(ERROR, message, ex, data, &block)
    end

    # Log any one or more of a message, an exception and structured data as FATAL.
    # @return [Boolean] true
    # @see Logging#debug
    def fatal(message = nil, ex = nil, data = nil, &block)
      _log(FATAL, message, ex, data, &block)
    end

    # Log any one or more of a message, an exception and structured data as UNKNOWN.
    # @return [Boolean] true
    # @see Logging#debug
    def unknown(message = nil, ex = nil, data = nil, &block)
      _log(UNKNOWN, message, ex, data, &block)
    end

    # Whether the current severity level allows for logging TRACE.
    # @return [Boolean] true if allows
    def trace?
      level <= TRACE
    end

    # Log any one or more of a message, an exception and structured data as specified log level.
    # If the block is given for delay evaluation, it returns them as an array or the one of them as a value.
    # @param severity [Integer] The log level.
    # @param message [String] The message to log. Use default_message if not specified.
    # @param ex [Exception] The exception or the error
    # @param data [Object] Any structured data
    # @yieldreturn [String|Exception|Object|Array] Any one or more of former parameters
    # @return [Boolean] true
    def add(severity, message = nil, ex = nil, data = nil, &block)
      _log(severity, message, ex, data, &block)
    end

    alias log add

    def _log(severity, *args)
      severity ||= UNKNOWN
      return true if level > severity
      append(severity, block_given? ? yield : args)
    end

    # @private
    def chain(_severity, _args, _fields, _hooks)
      raise NotImplementedError
    end

    protected

    # @private
    def append(severity, args)
      raise NotImplementedError
    end

    # @private
    def weak_merge!(base_data, inferior_data)
      base_data.merge!(inferior_data) do |_, base_v, inferior_v|
        if base_v.is_a?(Array) and inferior_v.is_a?(Array)
          (inferior_v + base_v).uniq
        elsif base_v.is_a?(Hash) and inferior_v.is_a?(Hash)
          weak_merge!(base_v, inferior_v)
        else
          base_v
        end
      end
    end
  end
end
