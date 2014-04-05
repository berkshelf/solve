module Solve
  class Constraint
    class << self
      # Coerce the object into a constraint.
      #
      # @param [Constraint, String]
      #
      # @return [Constraint]
      def coerce(object)
        if object.nil?
          Semverse::DEFAULT_CONSTRAINT
        else
          object.is_a?(self) ? object : new(object)
        end
      end

      # Split a constraint string into an Array of two elements. The first
      # element being the operator and second being the version string.
      #
      # If the given string does not contain a constraint operator then (=)
      # will be used.
      #
      # If the given string does not contain a valid version string then
      # nil will be returned.
      #
      # @param [#to_s] constraint
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
      def split(constraint)
        if constraint =~ /^[0-9]/
          operator = "="
          version  = constraint
        else
          _, operator, version = REGEXP.match(constraint).to_a
        end

        if operator.nil?
          raise Errors::InvalidConstraintFormat.new(constraint)
        end

        split_version = case version.to_s
        when /^(\d+)\.(\d+)\.(\d+)(-([0-9a-z\-\.]+))?(\+([0-9a-z\-\.]+))?$/i
          [ $1.to_i, $2.to_i, $3.to_i, $5, $7 ]
        when /^(\d+)\.(\d+)\.(\d+)?$/
          [ $1.to_i, $2.to_i, $3.to_i, nil, nil ]
        when /^(\d+)\.(\d+)?$/
          [ $1.to_i, $2.to_i, nil, nil, nil ]
        when /^(\d+)$/
          [ $1.to_i, nil, nil, nil, nil ]
        else
          raise Errors::InvalidConstraintFormat.new(constraint)
        end

        [ operator, split_version ].flatten
      end

      # @param [Semverse::Constraint] constraint
      # @param [Semverse::Version] target_version
      #
      # @return [Boolean]
      def compare_equal(constraint, target_version)
        target_version == constraint.version
      end

      # @param [Semverse::Constraint] constraint
      # @param [Semverse::Version] target_version
      #
      # @return [Boolean]
      def compare_gt(constraint, target_version)
        target_version > constraint.version
      end

      # @param [Semverse::Constraint] constraint
      # @param [Semverse::Version] target_version
      #
      # @return [Boolean]
      def compare_lt(constraint, target_version)
        target_version < constraint.version
      end

      # @param [Semverse::Constraint] constraint
      # @param [Semverse::Version] target_version
      #
      # @return [Boolean]
      def compare_gte(constraint, target_version)
        target_version >= constraint.version
      end

      # @param [Semverse::Constraint] constraint
      # @param [Semverse::Version] target_version
      #
      # @return [Boolean]
      def compare_lte(constraint, target_version)
        target_version <= constraint.version
      end

      # @param [Semverse::Constraint] constraint
      # @param [Semverse::Version] target_version
      #
      # @return [Boolean]
      def compare_approx(constraint, target_version)
        min = constraint.version
        max = if constraint.patch.nil?
          Semverse::Version.new([min.major + 1, 0, 0, 0])
        elsif constraint.build
          identifiers = constraint.version.identifiers(:build)
          replace     = identifiers.last.to_i.to_s == identifiers.last.to_s ? "-" : nil
          Semverse::Version.new([min.major, min.minor, min.patch, min.pre_release, identifiers.fill(replace, -1).join('.')])
        elsif constraint.pre_release
          identifiers = constraint.version.identifiers(:pre_release)
          replace     = identifiers.last.to_i.to_s == identifiers.last.to_s ? "-" : nil
          Semverse::Version.new([min.major, min.minor, min.patch, identifiers.fill(replace, -1).join('.')])
        else
          Semverse::Version.new([min.major, min.minor + 1, 0, 0])
        end
        min <= target_version && target_version < max
      end
    end

    OPERATOR_TYPES = {
      "~>" => :approx,
      "~"  => :approx,
      ">=" => :greater_than_equal,
      "<=" => :less_than_equal,
      "="  => :equal,
      ">"  => :greater_than,
      "<"  => :less_than,
    }.freeze

    COMPARE_FUNS = {
      approx: method(:compare_approx),
      greater_than_equal: method(:compare_gte),
      greater_than: method(:compare_gt),
      less_than_equal: method(:compare_lte),
      less_than: method(:compare_lt),
      equal: method(:compare_equal)
    }.freeze

    REGEXP = /^(#{OPERATOR_TYPES.keys.join('|')})\s?(.+)$/

    attr_reader :operator
    attr_reader :major
    attr_reader :minor
    attr_reader :patch
    attr_reader :pre_release
    attr_reader :build

    # Return the Semverse::Version representation of the major, minor, and patch
    # attributes of this instance
    #
    # @return [Semverse::Version]
    attr_reader :version

    # @param [#to_s] constraint
    def initialize(constraint = nil)
      constraint = constraint.to_s
      if constraint.nil? || constraint.empty?
        constraint = '>= 0.0.0'
      end

      @operator, @major, @minor, @patch, @pre_release, @build = self.class.split(constraint)

      unless operator_type == :approx
        @minor ||= 0
        @patch ||= 0
      end

      @version = Semverse::Version.new([
        self.major,
        self.minor,
        self.patch,
        self.pre_release,
        self.build,
      ])
    end

    # @return [Symbol]
    def operator_type
      unless type = OPERATOR_TYPES.fetch(operator)
        raise RuntimeError, "unknown operator type: #{operator}"
      end

      type
    end

    # Returns true or false if the given version would be satisfied by
    # the version constraint.
    #
    # @param [Version, #to_s] target
    #
    # @return [Boolean]
    def satisfies?(target)
      target = Version.coerce(target)

      return false if !version.zero? && greedy_match?(target)

      compare(target)
    end

    # dep-selector uses include? to determine if a version matches the
    # constriant.
    alias_method :include?, :satisfies?

    # @param [Object] other
    #
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) &&
        self.operator == other.operator &&
        self.version == other.version
    end
    alias_method :eql?, :==

    def inspect
      "#<#{self.class.to_s} #{to_s}>"
    end

    def to_s
      out =  "#{operator} #{major}"
      out << ".#{minor}" if minor
      out << ".#{patch}" if patch
      out << "-#{pre_release}" if pre_release
      out << "+#{build}" if build
      out
    end

    private

      # Returns true if the given version is a pre-release and if the constraint
      # does not include a pre-release and if the operator isn't < or <=.
      # This avoids greedy matches, e.g. 2.0.0.alpha won't satisfy >= 1.0.0.
      #
      # @param [Semverse::Version] target_version
      #
      def greedy_match?(target_version)
        operator_type !~ /less/ && target_version.pre_release? && !version.pre_release?
      end

      # @param [Semverse::Version] target
      #
      # @return [Boolean]
      def compare(target)
        COMPARE_FUNS.fetch(operator_type).call(self, target)
      end
  end
end
