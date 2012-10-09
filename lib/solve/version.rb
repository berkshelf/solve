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
        when /^(\d+)\.(\d+)\.(\d+)([+|-][0-9a-z-+\.]+)$/i
          [ $1.to_i, $2.to_i, $3.to_i, $4 ]
        when /^(\d+)\.(\d+)\.(\d+)$/
          [ $1.to_i, $2.to_i, $3.to_i, $4 ]
        when /^(\d+)\.(\d+)$/
          [ $1.to_i, $2.to_i, nil, nil ]
        when /^(\d+)$/
          [ $1.to_i, nil, nil, nil ]
        else
          raise Errors::InvalidVersionFormat.new(version_string)
        end
      end
    end

    include Comparable

    attr_reader :major
    attr_reader :minor
    attr_reader :patch
    attr_reader :special

    # @overload initialize(version_array)
    #   @param [Array] version_array
    #
    #   @example
    #     Version.new([1, 2, 3, '-rc.1+build.1']) => #<Version: @major=1, @minor=2, @patch=3, @special='-rc.1+build.1'>
    #
    # @overload initialize(version_string)
    #   @param [#to_s] version_string
    #
    #   @example
    #     Version.new("1.2.3-rc.1+build.1") => #<Version: @major=1, @minor=2, @patch=3, @special='-rc.1+build.1'>
    #
    # @overload initialize(version)
    #   @param [Solve::Version] version
    #
    #   @example
    #     Version.new(Version.new("1.2.3-rc.1+build.1")) => #<Version: @major=1, @minor=2, @patch=3, @special='-rc.1+build.1'>
    #
    def initialize(*args)
      if args.first.is_a?(Array)
        @major, @minor, @patch, @special = args.first
      else
        @major, @minor, @patch, @special = self.class.split(args.first.to_s)
      end

      @major ||= 0
      @minor ||= 0
      @patch ||= 0
      @special ||= nil
    end

    # @param [Solve::Version] other
    #
    # @return [Integer]
    def <=>(other)
      [:major, :minor, :patch].each do |method|
        ans = (self.send(method) <=> other.send(method))
        return ans if ans != 0
      end
      ans = specials_comparaison(other)
      return ans if ans != 0
      0
    end

    # @return [Array]
    def specials
      special.to_s.scan(/[-|+][0-9a-z\.]+/i).map do |special|
        [special[0]] + special[1..-1].split('.').map do |str|
          str.to_i.to_s == str ? str.to_i : str
        end
      end
    end

    # @param [Solve::Version] other
    #
    # @return [Integer]
    def specials_comparaison(other)
      [specials.length, other.specials.length].max.times do |i|
        if specials[i] && other.specials[i]
          ans = other.specials[i][0] <=> specials[i][0]
          return ans if ans != 0
          ([specials[i].length, other.specials[i].length].max - 1).times do |y|
            if specials[i][y+1].class == other.specials[i][y+1].class
              ans = specials[i][y+1] <=> other.specials[i][y+1]
              return ans if ans != 0
            elsif specials[i][y+1] && other.specials[i][y+1]
              return specials[i][y+1].class.to_s <=> other.specials[i][y+1].class.to_s
            elsif specials[i][y+1] || other.specials[i][y+1]
              return other.specials[i][y+1].class.to_s <=> specials[i][y+1].class.to_s
            end
          end
        elsif specials[i]
          return specials[i][0] == '-' ? -1 : 1
        elsif other.specials[i]
          return other.specials[i][0] == '-' ? 1 : -1
        end
      end
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
      "#{major}.#{minor}.#{patch}#{special}"
    end
  end
end
