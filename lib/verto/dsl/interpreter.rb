module Verto
  module DSL
    class Interpreter
      include DSL::Syntax

      def evaluate(vertofile_content=nil, attributes: {}, &block)
        with_attributes(attributes) do
          vertofile_content ? instance_eval(vertofile_content)  : instance_eval(&block)
        end
      end

      private

      def with_attributes(attributes, &block)
        attributes.each do |key, value|
          instance_variable_set("@#{key}", value)
          define_singleton_method(key) { instance_variable_get("@#{key}") }
        end

        block.call

        attributes.each do |key, value|
          instance_variable_set("@#{key}", nil)
          singleton_class.remove_method(key)
        end
      end
    end
  end
end
