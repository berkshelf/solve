module Solve
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Constraint
    class << self
      # @param [#to_s] string
      #
      # @return [Array, nil]
      def split(string)
        if string =~ /^[0-9]/
          op = "="
          ver = string
        else
          _, op, ver = REGEXP.match(string).to_a
        end

        return nil unless op || ver

        [ op, ver ]
      end

      # @param [Solve::Constraint] constraint
      # @param [Solve::Version] target_version
      #
      # @return [Boolean]
      def compare_equal(constraint, target_version)
        target_version == constraint.version
      end

      # @param [Solve::Constraint] constraint
      # @param [Solve::Version] target_version
      #
      # @return [Boolean]
      def compare_gt(constraint, target_version)
        target_version > constraint.version
      end

      # @param [Solve::Constraint] constraint
      # @param [Solve::Version] target_version
      #
      # @return [Boolean]
      def compare_lt(constraint, target_version)
        target_version < constraint.version
      end

      # @param [Solve::Constraint] constraint
      # @param [Solve::Version] target_version
      #
      # @return [Boolean]
      def compare_gte(constraint, target_version)
        target_version >= constraint.version
      end

      # @param [Solve::Constraint] constraint
      # @param [Solve::Version] target_version
      #
      # @return [Boolean]
      def compare_lte(constraint, target_version)
        target_version <= constraint.version
      end

      # @param [Solve::Constraint] constraint
      # @param [Solve::Version] target_version
      #
      # @return [Boolean]
      def compare_aprox(constraint, target_version)
        unless constraint.patch.nil?
          target_version.patch >= constraint.patch &&
            target_version.minor == constraint.minor &&
            target_version.major == constraint.major
        else
          target_version.minor >= constraint.minor &&
            target_version.major == constraint.major
        end
      end
    end

    OPERATORS = {
      "=" => method(:compare_equal),
      ">" => method(:compare_gt),
      "<" => method(:compare_lt),
      ">=" => method(:compare_gte),
      "<=" => method(:compare_lte),
      "~>" => method(:compare_aprox)
    }.freeze

    REGEXP = /^(#{OPERATORS.keys.join('|')}) (.+)$/

    attr_reader :operator
    attr_reader :major
    attr_reader :minor
    attr_reader :patch

    # @param [#to_s] constraint
    def initialize(constraint = ">= 0.0.0")
      @operator, ver_str = self.class.split(constraint)
      if @operator.nil? || ver_str.nil?
        raise InvalidConstraintFormat.new(constraint)
      end

      @major, @minor, @patch = Version.split(ver_str)
      @compare_fun = OPERATORS[self.operator]
    end

    def version
      Version.new([self.major, self.minor, self.patch])
    end

    # Returns true or false if the given version would be satisfied by
    # the version constraint.
    #
    # @param [#to_s] target_version
    #
    # @return [Boolean]
    def satisfies?(target_version)
      target_version = Version.new(target_version.to_s)

      @compare_fun.call(self, target_version)
    end

    # @param [Object] other
    #
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) &&
        self.operator == other.operator &&
        self.major == other.minor &&
        self.minor == other.minor &&
        self.patch == other.patch
    end
    alias_method :eql?, :==

    def to_s
      "#{operator} #{major}.#{minor}.#{patch}"
    end
  end
end
