module Solve
  # @author Jamie Winsor <reset@riotgames.com>
  module Errors
    class SolveError < StandardError
      alias_method :mesage, :to_s
    end

    class InvalidVersionFormat < SolveError
      attr_reader :version

      # @param [#to_s] version
      def initialize(version)
        @version = version
      end

      def to_s
        "'#{version}' did not contain a valid version string: 'x.y.z' or 'x.y'."
      end
    end

    class InvalidConstraintFormat < SolveError
      attr_reader :constraint

      # @param [#to_s] constraint
      def initialize(constraint)
        @constraint = constraint
      end

      def to_s
        "'#{constraint}' did not contain a valid operator or a valid version string."
      end
    end

    class NoSolutionError < SolveError; end
  end
end
