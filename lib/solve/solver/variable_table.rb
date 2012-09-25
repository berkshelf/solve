module Solve
  class Solver
    # @author Andrew Garson <andrew.garson@gmail.com>
    # @author Jamie Winsor <jamie@vialstudios.com>
    class VariableTable
      attr_reader :rows

      def initialize
        @rows = Array.new
      end

      def add(package, source)
        row = rows.detect { |row| row.package == package }
        if row.nil?
          @rows << Variable.new(package, source)
        else
          row.add_source(source)
        end
      end

      def first_unbound
        @rows.detect { |row| row.bound? == false }
      end

      def find_package(package)
        @rows.detect { |row| row.package == package }
      end

      def remove_all_with_only_this_source!(source)
        with_only_this_source, others = @rows.partition { |row| row.sources == [source] }
        @rows = others
        with_only_this_source
      end

      def all_from_source(source)
        @rows.select { |row| row.sources.include?(source) }
      end

      def before(package)
        package_index = @rows.index { |row| row.package == package }
        (package_index == 0) ? nil : @rows[package_index - 1]
      end

      def all_after(package)
        package_index = @rows.index { |row| row.package == package }
        @rows[(package_index+1)..-1]
      end
    end
  end
end
