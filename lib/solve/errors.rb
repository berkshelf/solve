module Solve
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Errors
    class SolveError < StandardError; end

    class InvalidVersionFormat < SolveError
      attr_reader :version

      # @param [#to_s] version
      def initialize(version)
        @version = version
      end

      def message
        "'#{version}' did not contain a valid version string: 'x.y.z' or 'x.y'."
      end
    end

    class InvalidConstraintFormat < SolveError
      attr_reader :constraint

      # @param [#to_s] constraint
      def initialize(constraint)
        @constraint = constraint
      end

      def message
        "'#{constraint}' did not contain a valid operator or a valid version string."
      end
    end

    class NoSolutionError < SolveError
      attr_reader :errors

      def initialize(errors = [])
        @errors = errors
      end
    end
  end
end
