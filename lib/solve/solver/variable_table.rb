module Solve
  class Solver
    # @author Andrew Garson <andrew.garson@gmail.com>
    # @author Jamie Winsor <jamie@vialstudios.com>
    class VariableTable
      attr_reader :rows

      def initialize
        @rows = Array.new
      end

      def add(artifact, source)
        row = rows.detect { |row| row.artifact == artifact }
        if row.nil?
          @rows << VariableRow.new(artifact, source)
        else
          row.add_source(source)
        end
      end

      def first_unbound
        @rows.detect { |row| row.bound? == false }
      end

      def find_artifact(artifact)
        @rows.detect { |row| row.artifact == artifact }
      end

      def remove_all_with_only_this_source!(source)
        with_only_this_source, others = @rows.partition { |row| row.sources == [source] }
        @rows = others
        with_only_this_source
      end

      def all_from_source(source)
        @rows.select { |row| row.sources.include?(source) }
      end

      def before(artifact)
        artifact_index = @rows.index { |row| row.artifact == artifact }
        (artifact_index == 0) ? nil : @rows[artifact_index - 1]
      end

      def all_after(artifact)
        artifact_index = @rows.index { |row| row.artifact == artifact }
        @rows[(artifact_index+1)..-1]
      end
    end
  end
end
