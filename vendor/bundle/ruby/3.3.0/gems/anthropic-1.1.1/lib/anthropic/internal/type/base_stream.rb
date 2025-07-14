# frozen_string_literal: true

module Anthropic
  module Internal
    module Type
      # @api private
      #
      # @generic Elem
      #
      # This module provides a base implementation for streaming responses in the SDK.
      #
      # @see https://rubyapi.org/3.2/o/enumerable
      module BaseStream
        include Enumerable

        class << self
          # Attempt to close the underlying transport when the stream itself is garbage
          # collected.
          #
          # This should not be relied upon for resource clean up, as the garbage collector
          # is not guaranteed to run.
          #
          # @param stream [Enumerable<Object>]
          #
          # @return [Proc]
          #
          # @see https://rubyapi.org/3.2/o/objectspace#method-c-define_finalizer
          def defer_closing(stream) = ->(_id) { Anthropic::Internal::Util.close_fused!(stream) }
        end

        # @api public
        #
        # @return [void]
        def close = Anthropic::Internal::Util.close_fused!(@iterator)

        # @api private
        #
        # @return [Enumerable<generic<Elem>>]
        private def iterator = (raise NotImplementedError)

        # @api public
        #
        # @param blk [Proc]
        #
        # @yieldparam [generic<Elem>]
        # @return [void]
        def each(&blk)
          unless block_given?
            raise ArgumentError.new("A block must be given to ##{__method__}")
          end
          @iterator.each(&blk)
        end

        # @api public
        #
        # @return [Enumerator<generic<Elem>>]
        def to_enum = @iterator

        alias_method :enum_for, :to_enum

        # @api private
        #
        # @param model [Class, Anthropic::Internal::Type::Converter]
        # @param url [URI::Generic]
        # @param status [Integer]
        # @param response [Net::HTTPResponse]
        # @param stream [Enumerable<Object>]
        def initialize(model:, url:, status:, response:, stream:)
          @model = model
          @url = url
          @status = status
          @response = response
          @stream = stream
          @iterator = iterator

          ObjectSpace.define_finalizer(self, Anthropic::Internal::Type::BaseStream.defer_closing(@stream))
        end

        # @api private
        #
        # @return [String]
        def inspect
          model = Anthropic::Internal::Type::Converter.inspect(@model, depth: 1)

          "#<#{self.class}[#{model}]:0x#{object_id.to_s(16)}>"
        end
      end
    end
  end
end
