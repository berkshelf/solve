require 'spec_helper'

describe "Solutions" do
  it "chooses the best artifact for the demands" do
    graph = Solve::Graph.new
    graph.artifacts("mysql", "2.0.0")
    graph.artifacts("mysql", "1.2.0")
    graph.artifacts("nginx", "1.0.0").depends("mysql", ">= 1.2.0")
    
    result = Solve.it!(graph, [['nginx', '= 1.0.0'], ['mysql']])

    result.should eql("nginx" => "1.0.0", "mysql" => "2.0.0")
  end

  it "raises NoSolutionError when a solution cannot be found" do    
    graph = Solve::Graph.new
    graph.artifacts("mysql", "1.2.0")

    lambda {
      Solve.it!(graph, ['mysql', '>= 2.0.0'])
    }.should raise_error(Solve::Errors::NoSolutionError)
  end
end
