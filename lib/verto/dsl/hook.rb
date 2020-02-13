module Verto
  module DSL
    class Hook
      MOMENT = %i[before after]

      module Contexts
        class Any
          def match?(_)
            true
          end
        end

        class Command < Struct.new(:name)
          def match?(command_name)
            name == command_name
          end
        end
      end

      InvalidWhenError = Class.new(StandardError)

      attr_accessor :moment

      def initialize(parser: DSL.parser, moment: :before, on: Contexts::Any.new, &block)
        raise InvalidWhenError.new("Must be some of these: #{MOMENT}") unless MOMENT.include?(moment)

        @moment = moment
        @parser = parser
        @context = on
        @block = block
      end

      def call(current_context = nil, with_attributes: {})
        # TODO: Move to Parser class
        with_attributes.each do |key, value|
          @parser.instance_variable_set("@#{key}", value)
          @parser.define_singleton_method(key) { @new_version }
        end

        @parser.instance_eval(&@block) if @context.match?(current_context)
      end
    end
  end
end
