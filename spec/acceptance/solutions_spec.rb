require 'spec_helper'

describe "Solutions" do
  it "solves stuff" do
    graph = Solve::Graph.new
    graph.artifacts("mysql", "1.2.0")
    graph.artifacts("nginx", "1.0.0").depends("mysql", "~> 1.0.0")
    graph.demands('nginx', '>= 0.100.0')

    Solve.it(graph).should eql("nginx" => "1.0.0", "mysql" => "1.2.0")
  end
end
