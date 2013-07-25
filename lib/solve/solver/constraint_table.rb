module Solve
  class Solver
    class ConstraintTable
      attr_reader :rows

      def initialize
        @rows = Array.new
      end

      # @param [Solve::Dependency] dependency
      # @param [String, Symbol] source
      #
      # @return [Array<ConstraintRow>]
      def add(dependency, source)
        @rows << ConstraintRow.new(dependency, source)
      end

      def constraints_on_artifact(name)
        @rows.select do |row|
          row.name == name
        end.map { |row| row.constraint }
      end

      def remove_constraints_from_source!(source)
        from_source, others = @rows.partition { |row| row.source == source }
        @rows = others
        from_source
      end
    end
  end
end
