module Solve
  class Solver
    # @author Andrew Garson <andrew.garson@gmail.com>
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Variable
      attr_reader :package
      attr_reader :value
      attr_reader :sources

      def initialize(package, source)
        @package = package
        @value = nil
        @sources = Array(source)
      end

      def add_source(source)
        @sources << source
      end

      def last_source
        @sources.last
      end

      def bind(value)
        @value = value
      end

      def unbind
        @value = nil
      end

      def bound?
        !@value.nil?
      end

      def remove_source(source)
        @sources.delete(source)
      end
    end
  end
end
