module Solve
  module Tracers
    class << self
      # @param [#say] ui
      #
      # @returns [AbstractTracer]
      def build(ui)
        unless ui.respond_to?(:say)
          Solve::Tracers::Silent.new
        else
          Solve::Tracers::HumanReadable.new(ui)
        end
      end
    end

    class AbstractTracer
      class << self
        private

          def must_define(*args)
            args.each do |method|
              define_method(method.to_sym) do |*args|
                raise AbstractFunction, "##{method} must be defined on #{self.class}"
              end
            end
          end
      end

      TRACER_METHODS = [
        :start,
        :searching_for,
        :add_constraint,
        :possible_values,
        :trying,
        :backtrack,
        :cannot_backtrack,
        :solution,
        :reset_domain,
        :unbind,
        :remove_variable,
        :remove_constraint,
      ]

      must_define *TRACER_METHODS
    end
  end
end

require_relative 'tracers/human_readable'
require_relative 'tracers/silent'
