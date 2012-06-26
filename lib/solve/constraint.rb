module Solve
  class Constraint
    class << self
      # @param [#to_s] string
      #
      # @return [Array, nil]
      def parse(string)
        _, op, ver = REGEXP.match(string).to_a
        unless op || ver
          return nil
        end
        [ op, ver ]
      end
    end

    OPERATORS = [
      "=",
      ">",
      "<",
      ">=",
      "<=",
      "~>"
    ]
    REGEXP = /^(#{OPERATORS.join('|')}) (.+)$/

    attr_reader :operator
    attr_reader :version

    # @param [#to_s] constraint
    def initialize(constraint = ">= 0.0.0")
      @operator, ver_str = self.class.parse(constraint)
      if @operator.nil? || ver_str.nil?
        raise InvalidConstraintFormat.new(constraint)
      end

      @version = Version.new(ver_str)
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
      "#{operator} #{version}"
    end
  end
end
