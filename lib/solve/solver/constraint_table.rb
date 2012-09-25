module Solve
  class Solver
    # @author Andrew Garson <andrew.garson@gmail.com>
    # @author Jamie Winsor <jamie@vialstudios.com>
    class ConstraintTable
      attr_reader :rows

      def initialize
        @rows = Array.new
      end

      def add(package, constraint, source)
        @rows << ConstraintRow.new(package, constraint, source)
      end

      def constraints_on_package(package)
        @rows.select do |row|
          row.package == package
        end.map { |row| row.constraint }
      end

      def remove_constraints_from_source!(source)
        @rows.reject! { |row| row.source == source }
      end
    end
  end
end
