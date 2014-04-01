require 'set'
require 'tsort'

module Solve
  class Graph
    include TSort

    def initialize
      @nodes = {}
    end

    def node(object)
      @nodes[object] ||= Set.new
      self
    end

    def nodes
      @nodes.keys
    end

    def each_node(&block)
      nodes.each(&block)
    end
    alias_method :tsort_each_node, :each_node

    def edge(a, b)
      node(a)
      node(b)

      @nodes[a].add(b)
    end

    def adjacencies(object)
      @nodes[object] || Set.new
    end

    def each_adjacency(object, &block)
      adjacencies(object).each(&block)
    end
    alias_method :tsort_each_child, :each_adjacency

    def remove(object)
      if node = @nodes.delete(object)
        node.clear # Poor man's GC
      end
    end

    #
    # Convert the current graph to a DOT. This is an intermediate step in
    # generating a PNG.
    #
    # @return [String]
    #
    def to_dot
      out = %|digraph Solve__Graph {\n|

      nodes.each do |node|
        out << %|  "#{node}" [ fontsize = 8, label = "#{node}" ]\n|
      end

      nodes.each do |node|
        adjacencies(node).each do |edge|
          out << %|  "#{node}" -> "#{edge}" [ fontsize = 8 ]\n|
        end
      end

      out << %|}|
      out
    end

    #
    # Save the graph visually as a PNG.
    #
    def to_png
      contents = to_dot

      File.open('graph.dot', 'w') do |f|
        f.write(to_dot)
      end

      system('dot -T png graph.dot -o graph.png')
    end
  end
end
