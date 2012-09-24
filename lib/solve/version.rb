module Solve
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Version
    class << self
      # @param [#to_s] version_string
      #
      # @raise [InvalidVersionFormat]
      #
      # @return [Array]
      def split(version_string)
        major, minor, patch = case version_string.to_s
        when /^(\d+)\.(\d+)\.(\d+)$/
          [ $1.to_i, $2.to_i, $3.to_i ]
        when /^(\d+)\.(\d+)$/
          [ $1.to_i, $2.to_i, nil ]
        else
          raise Errors::InvalidVersionFormat.new(version_string)
        end
      end
    end

    include Comparable

    attr_reader :major
    attr_reader :minor
    attr_reader :patch

    # @overload initialize(version_array)
    #   @param [Array] version_array
    #
    #   @example
    #     Version.new([1, 2, 3]) => #<Version: @major=1, @minor=2, @patch=3>
    #
    # @overload initialize(version_string)
    #   @param [#to_s] version_string
    #
    #   @example
    #     Version.new("1.2.3") => #<Version: @major=1, @minor=2, @patch=3>
    #
    # @overload initialize(version)
    #   @param [Solve::Version] version
    #
    #   @example
    #     Version.new(Version.new("1.2.3")) => #<Version: @major=1, @minor=2, @patch=3>
    #
    def initialize(*args)
      args.first.is_a?(Array)
      case args.first
      when Array
        @major, @minor, @patch = args.first
      when String
        @major, @minor, @patch = self.class.split(args.first.to_s)
      when Solve::Version
        version = args.first
        @major, @minor, @patch = version.major, version.minor, version.patch
      end

      @major ||= 0
      @minor ||= 0
      @patch ||= 0
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
