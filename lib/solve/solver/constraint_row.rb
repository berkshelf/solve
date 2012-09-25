module Solve
  class Solver
    # @author Andrew Garson <andrew.garson@gmail.com>
    # @author Jamie Winsor <jamie@vialstudios.com>
    class ConstraintRow
      attr_reader :package
      attr_reader :constraint
      attr_reader :source

      def initialize(package, constraint, source)
        @package = package
        @constraint = constraint
        @source = source
      end
    end
  end
end
