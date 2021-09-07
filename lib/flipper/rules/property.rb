require 'flipper/rules/object'

module Flipper
  module Rules
    class Property < Object
      def initialize(value)
        @type = "property".freeze
        @value = value.to_s
      end

      def name
        @value
      end
    end
  end
end