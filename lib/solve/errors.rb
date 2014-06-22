module Solve
  module Errors
    class SolveError < StandardError
      alias_method :mesage, :to_s
    end

    class NoSolutionError < SolveError

      # Artifacts that don't exist at any version but are required for a valid
      # solution
      # @return [Array<String>] Missing artifact names
      attr_reader :missing_artifacts

      # Constraints that eliminate all versions of an artifact, e.g. you ask
      # for mysql >= 2.0.0 but only 1.0.0 exists.
      # @return [Array<String>] Invalid constraints as strings
      attr_reader :constraints_excluding_all_artifacts

      # A demand that has conflicting dependencies
      # @return [String] the unsatisfiable demand
      attr_reader :unsatisfiable_demand

      # The artifact for which there are conflicting dependencies
      # @return [Array<String>] The "most constrained" artifacts
      attr_reader :artifacts_with_no_satisfactory_version

      # @param [#to_s] message
      # @option causes [Array<String>] :missing_artifacts ([])
      # @option causes [Array<String>] :constraints_excluding_all_artifacts ([])
      # @option causes [#to_s] :unsatisfiable_demand (nil)
      # @option causes [Array<String>] :artifacts_with_no_satisfactory_version ([])
      def initialize(message = nil, causes = {})
        super(message)
        @message = message
        @missing_artifacts = causes[:missing_artifacts] || []
        @constraints_excluding_all_artifacts = causes[:constraints_excluding_all_artifacts] || []
        @unsatisfiable_demand = causes[:unsatisfiable_demand] || nil
        @artifacts_with_no_satisfactory_version = causes[:artifacts_with_no_satisfactory_version] || []
      end

      def to_s
        s = ""
        s << "#{@message}\n"
        s << "Missing artifacts: #{missing_artifacts.join(',')}\n" unless missing_artifacts.empty?
        unless constraints_excluding_all_artifacts.empty?
	  pretty = constraints_excluding_all_artifacts.map { |constraint| "(#{constraint[0]} #{constraint[1]})" }.join(',')
          s << "Constraints that match no available version: #{pretty}\n"
        end
        s << "Demand that cannot be met: #{unsatisfiable_demand}\n" if unsatisfiable_demand
        unless artifacts_with_no_satisfactory_version.empty?
          s << "Artifacts for which there are conflicting dependencies: #{artifacts_with_no_satisfactory_version.join(',')}"
        end
        s
      end

    end

    # Indicates that the solver could not find the conflicting constraints when
    # solving the given demands and graph.
    class NoSolutionCauseUnknown < NoSolutionError; end

    class UnsortableSolutionError < SolveError
      attr_reader :internal_exception
      attr_reader :unsorted_solution

      def initialize(internal_exception, unsorted_solution)
        @internal_exception = internal_exception
        @unsorted_solution  = unsorted_solution
      end

      def to_s
        "The solution contains a cycle and cannot be topologically sorted. See #unsorted_solution on this exception for the unsorted solution"
      end
    end
  end
end
