module Solve
  module Tracers
    class HumanReadable < AbstractTracer
      extend Forwardable

      attr_reader :ui

      def_delegator :ui, :say

      # @param [#say] ui
      def initialize(ui)
        @ui = ui
      end

      def start
        say("Attempting to find a solution")
      end

      def searching_for(unbound_variable, constraints, possible_values)
        say("Searching for a value for #{unbound_variable.artifact}")
        say("Constraints are #{constraints.join("\n\t")}")
        possible_values(possible_values)
      end

      def possible_values(possible_values)
        say("Possible values are #{possible_values.map(&:to_s).join("\n\t")}")
      end

      def trying(artifact)
        say("Attempting to use #{artifact.to_s}")
      end

      def backtrack(unbound_variable)
        say("Could not find an acceptable value for #{unbound_variable.artifact.to_s}")
      end

      def cannot_backtrack
        say("Cannot backtrack any further")
      end

      def solution(solution)
        say("Found Solution")
        say(solution.inspect)
      end

      def add_constraint(dependency, source)
        say("Adding constraint #{dependency.name} #{dependency.constraint} from #{source.to_s}")
      end

      def reset_domain(variable)
        say("Resetting possible values for #{variable.artifact.to_s}")
      end

      def unbind(variable)
        say("Unbinding #{variable.artifact.to_s}")
      end

      def remove_variable(variable)
        say("Removed variable #{variable.artifact.to_s}")
      end

      def remove_constraint(constraint)
        say("Removed constraint #{constraint.name} #{constraint.constraint}")
      end
    end
  end
end
