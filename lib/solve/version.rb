module Solve
  class Version
    include Comparable

    attr_reader :major
    attr_reader :minor
    attr_reader :patch

    # @param [String] string
    def initialize(ver_str = String.new)
      @major, @minor, @patch = parse(ver_str)
    end

    def <=>(other)
      [:major, :minor, :patch].each do |method|
        ans = (self.send(method) <=> other.send(method))
        return ans if ans != 0
      end
      0
    end

    def eql?(other)
      other.is_a?(Version) && self == other
    end

    def inspect
      to_s
    end

    def to_s
      "#{major}.#{minor}.#{patch}"
    end

    private

      def parse(ver_str = String.new)
        @major, @minor, @patch = case ver_str.to_s
        when /^(\d+)\.(\d+)\.(\d+)$/
          [ $1.to_i, $2.to_i, $3.to_i ]
        when /^(\d+)\.(\d+)$/
          [ $1.to_i, $2.to_i, 0 ]
        else
          raise InvalidVersionFormat.new(ver_str)
        end
      end
  end
end
