module Solve
  # @author Jamie Winsor <jamie@vialstudios.com>
  # @author Thibaud Guillaume-Gentil <thibaud@thibaud.me>
  class Constraint
    class << self
      # Split a constraint string into an Array of two elements. The first
      # element being the operator and second being the version string.
      #
      # If the given string does not contain a constraint operator then (=)
      # will be used.
      #
      # If the given string does not contain a valid version string then
      # nil will be returned.
      #
      # @param [#to_s] string
      #
      # @example splitting a string with a constraint operator and valid version string
      #   Constraint.split(">= 1.0.0") => [ ">=", "1.0.0" ]
      #
      # @example splitting a string without a constraint operator
      #   Constraint.split("0.0.0") => [ "=", "1.0.0" ]
      #
      # @example splitting a string without a valid version string
      #   Constraint.split("hello") => nil
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
        min = constraint.version
        if constraint.patch == nil
          max = Version.new([min.major + 1, 0, 0, 0])
        elsif constraint.build
          identifiers = constraint.version.identifiers(:build)
          replace = identifiers.last.to_i.to_s == identifiers.last.to_s ? "-" : nil
          max = Version.new([min.major, min.minor, min.patch, min.pre_release, identifiers.fill(replace, -1).join('.')])
        elsif constraint.pre_release
          identifiers = constraint.version.identifiers(:pre_release)
          replace = identifiers.last.to_i.to_s == identifiers.last.to_s ? "-" : nil
          max = Version.new([min.major, min.minor, min.patch, identifiers.fill(replace, -1).join('.')])
        else
          max = Version.new([min.major, min.minor + 1, 0, 0])
        end
        min <= target_version && target_version < max
      end
    end

    OPERATORS = {
      "~>" => method(:compare_aprox),
      ">=" => method(:compare_gte),
      "<=" => method(:compare_lte),
      "=" => method(:compare_equal),
      "~" => method(:compare_aprox),
      ">" => method(:compare_gt),
      "<" => method(:compare_lt)
    }.freeze

    REGEXP = /^(#{OPERATORS.keys.sort{|a,b| b.length <=> a.length}.join('|')})\s?(.+)$/

    attr_reader :operator
    attr_reader :major
    attr_reader :minor
    attr_reader :patch
    attr_reader :pre_release
    attr_reader :build

    # @param [#to_s] constraint
    def initialize(constraint = ">= 0.0.0")
      @operator, ver_str = self.class.split(constraint)
      if @operator.nil? || ver_str.nil?
        raise Errors::InvalidConstraintFormat.new(constraint)
      end

      @major, @minor, @patch, @pre_release, @build = Version.split(ver_str)
      @compare_fun = OPERATORS.fetch(self.operator)
    end

    # Return the Solve::Version representation of the major, minor, and patch
    # attributes of this instance
    #
    # @return [Solve::Version]
    def version
      @version ||= Version.new(
        [
          self.major,
          self.minor,
          self.patch,
          self.pre_release,
          self.build
        ]
      )
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
        self.version == other.version
    end
    alias_method :eql?, :==

    def to_s
      str = operator
      str += " #{major}.#{minor}.#{patch}"
      str += "-#{pre_release}" if pre_release
      str += "+#{build}" if build
      str
    end
  end
end
