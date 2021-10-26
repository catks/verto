# frozen_string_literal: true

module Verto
  module DSL
    class UpdateChangelog
      module FilteredBy
        def self.included(klass)
          klass.extend(ClassMethods)
        end

        module ClassMethods
          def filtered_by(filter)
            Proxy.new(self, filter)
          end
        end

        class Proxy
          def initialize(filter_class, final_filter)
            @filter_class = filter_class
            @final_filter = final_filter
          end

          def new
            filter_object

            self
          end

          def call(*args)
            filter_object
              .call(*args)
              .select { |message| @final_filter.match?(message) }
          end

          private

          # Lazy evaluete object to load Verto dependencies only at the last
          def filter_object
            @filter_object ||= @filter_class.new
          end
        end
      end
    end
  end
end
