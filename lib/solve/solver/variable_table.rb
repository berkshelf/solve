module Solve
  class Solver
    # @author Andrew Garson <andrew.garson@gmail.com>
    # @author Jamie Winsor <jamie@vialstudios.com>
    class VariableTable
      attr_reader :rows

      def initialize
        @rows = Array.new
      end

      # @param [String] artifact
      # @param [String] source
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

      # @param [String] artifact
      def find_artifact(artifact)
        @rows.detect { |row| row.artifact == artifact }
      end

      # @param [String] source
      def remove_all_with_only_this_source!(source)
        with_only_this_source, others = @rows.partition { |row| row.sources == [source] }
        @rows = others
        with_only_this_source
      end

      # @param [String] source
      def all_from_source(source)
        @rows.select { |row| row.sources.include?(source) }
      end

      # @param [String] artifact
      def before(artifact)
        artifact_index = @rows.index { |row| row.artifact == artifact }
        (artifact_index == 0) ? nil : @rows[artifact_index - 1]
      end

      # @param [String] artifact
      def all_after(artifact)
        artifact_index = @rows.index { |row| row.artifact == artifact }
        @rows[(artifact_index+1)..-1]
      end

      # @param [String] artifact
      def get_dependents(artifact)
        return [] if artifact == :root
        row = @rows.detect { |row| row.artifact == artifact }
        roots = []
        find_roots(row, roots)
      end

      private
        def find_roots(row, roots)

          if row.sources.any? { |source| source == :root }
            roots << row.artifact unless roots.include? row.artifact
            return roots
          end

          row.sources.each do |source|
            source_row = @rows.detect { |row| row.artifact == source.name }
            find_roots(source_row, roots)
          end

          roots
        end
    end
  end
end
