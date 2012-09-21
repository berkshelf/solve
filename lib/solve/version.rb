module Solve
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Version
    class << self
      # @param [#to_s] version_string
      #
      # @raise [InvalidVersionFormat]
      #
      # @return [Array]
      def from_string(version_string)
        major, minor, patch = case version_string.to_s
        when /^(\d+)\.(\d+)\.(\d+)$/
          [ $1.to_i, $2.to_i, $3.to_i ]
        when /^(\d+)\.(\d+)$/
          [ $1.to_i, $2.to_i, 0 ]
        else
          raise InvalidVersionFormat.new(version_string)
        end
      end
    end

    include Comparable

    attr_reader :major
    attr_reader :minor
    attr_reader :patch

    # @param [#to_s] version_string
    def initialize(version_string = String.new)
      @major, @minor, @patch = self.class.from_string(version_string.to_s)
    end

    # @param [Solve::Version] other
    #
    # @return [Integer]
    def <=>(other)
      [:major, :minor, :patch].each do |method|
        ans = (self.send(method) <=> other.send(method))
        return ans if ans != 0
      end
      0
    end

    # @param [Solve::Version] other
    #
    # @return [Boolean]
    def eql?(other)
      other.is_a?(Version) && self == other
    end

    def inspect
      to_s
    end

    def to_s
      "#{major}.#{minor}.#{patch}"
    end
  end
end
