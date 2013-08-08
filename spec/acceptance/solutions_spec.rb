require 'spec_helper'

describe "Solutions" do

  def sanitize_result(result)
    result.each_pair { |k, v| result[k] = v[:version] }
  end
  
  it "chooses the correct artifact for the demands" do
    graph = Solve::Graph.new
    graph.artifacts("mysql", "2.0.0")
    graph.artifacts("mysql", "1.2.0")
    graph.artifacts("nginx", "1.0.0").depends("mysql", "= 1.2.0")

    result = sanitize_result Solve.it!(graph, [['nginx', '= 1.0.0'], ['mysql']])

    result.should eql("nginx" => "1.0.0", "mysql" => "1.2.0")
  end

  it "chooses the best artifact for the demands" do
    graph = Solve::Graph.new
    graph.artifacts("mysql", "2.0.0")
    graph.artifacts("mysql", "1.2.0")
    graph.artifacts("nginx", "1.0.0").depends("mysql", ">= 1.2.0")
    
    result = sanitize_result Solve.it!(graph, [['nginx', '= 1.0.0'], ['mysql']])

    result.should eql("nginx" => "1.0.0", "mysql" => "2.0.0")
  end

  it "does not raise NoSolutionError when a solution cannot be found" do    
    graph = Solve::Graph.new
    graph.artifacts("mysql", "1.2.0")

    result = sanitize_result Solve.it!(graph, ['mysql', '>= 2.0.0'])
  end

  it "find the correct solution when backtracking in variables introduced via demands" do
    graph = Solve::Graph.new

    graph.artifacts("D", "1.2.0")
    graph.artifacts("D", "1.3.0")
    graph.artifacts("D", "1.4.0")
    graph.artifacts("D", "2.0.0")
    graph.artifacts("D", "2.1.0")

    graph.artifacts("C", "2.0.0").depends("D", "= 1.2.0")
    graph.artifacts("C", "2.1.0").depends("D", ">= 2.1.0")
    graph.artifacts("C", "2.2.0").depends("D", "> 2.0.0")

    graph.artifacts("B", "1.0.0").depends("D", "= 1.0.0")
    graph.artifacts("B", "1.1.0").depends("D", "= 1.0.0")
    graph.artifacts("B", "2.0.0").depends("D", ">= 1.3.0")
    graph.artifacts("B", "2.1.0").depends("D", ">= 2.0.0")

    graph.artifacts("A", "1.0.0").depends("B", "> 2.0.0")
    graph.artifacts("A", "1.0.0").depends("C", "= 2.1.0")
    graph.artifacts("A", "1.0.1").depends("B", "> 1.0.0")
    graph.artifacts("A", "1.0.1").depends("C", "= 2.1.0")
    graph.artifacts("A", "1.0.2").depends("B", "> 1.0.0")
    graph.artifacts("A", "1.0.2").depends("C", "= 2.0.0")

    result = sanitize_result Solve.it!(graph, [['A', '~> 1.0.0'], ['D', ">= 2.0.0"]])


    result.should eql("A" => "1.0.1",
                      "B" => "2.1.0",
                      "C" => "2.1.0",
                      "D" => "2.1.0")
  end

  it "finds the correct solution when there is a circular dependency" do
    graph = Solve::Graph.new

    graph.artifacts("A", "1.0.0").depends("B", "1.0.0")
    graph.artifacts("B", "1.0.0").depends("C", "1.0.0")
    graph.artifacts("C", "1.0.0").depends("A", "1.0.0")

    result = sanitize_result Solve.it!(graph, [["A", "1.0.0"]])

    result.should eql("A" => "1.0.0", 
                      "B" => "1.0.0",
                      "C" => "1.0.0")
  end

  it "finds the correct solution when there is a p shaped depenency chain" do
    graph = Solve::Graph.new

    graph.artifacts("A", "1.0.0").depends("B", "1.0.0")
    graph.artifacts("B", "1.0.0").depends("C", "1.0.0")
    graph.artifacts("C", "1.0.0").depends("B", "1.0.0")

    result = sanitize_result Solve.it!(graph, [["A", "1.0.0"]])

    result.should eql("A" => "1.0.0", 
                      "B" => "1.0.0",
                      "C" => "1.0.0")
  end

  it "finds the correct solution when there is a diamond shaped dependency" do
    graph = Solve::Graph.new

    graph.artifacts("A", "1.0.0").depends("B", "1.0.0").depends("C", "1.0.0")
    graph.artifacts("B", "1.0.0").depends("D", "1.0.0")
    graph.artifacts("C", "1.0.0").depends("D", "1.0.0")
    graph.artifacts("D", "1.0.0")

    result = sanitize_result Solve.it!(graph, [["A", "1.0.0"]])

    result.should eql("A" => "1.0.0",
                      "B" => "1.0.0",
                      "C" => "1.0.0",
                      "D" => "1.0.0")
  end

  it "gives an empty solution when there are no demands" do
    graph = Solve::Graph.new
    result = sanitize_result Solve.it!(graph, [])
    result.should eql({})
  end

  it "tries all combinations until it finds a solution" do

    graph = Solve::Graph.new

    graph.artifacts("A", "1.0.0").depends("B", "~> 1.0.0")
    graph.artifacts("A", "1.0.1").depends("B", "~> 1.0.0")
    graph.artifacts("A", "1.0.2").depends("B", "~> 1.0.0")

    graph.artifacts("B", "1.0.0").depends("C", "~> 1.0.0")
    graph.artifacts("B", "1.0.1").depends("C", "~> 1.0.0")
    graph.artifacts("B", "1.0.2").depends("C", "~> 1.0.0")

    graph.artifacts("C", "1.0.0").depends("D", "1.0.0")
    graph.artifacts("C", "1.0.1").depends("D", "1.0.0")
    graph.artifacts("C", "1.0.2").depends("D", "1.0.0")

    # ensure we can't find a solution in the above
    graph.artifacts("D", "1.0.0").depends("A", "< 0.0.0")

    # Add a solution to the graph that should be reached only after
    #   all of the others have been tried 
    #   it must be circular to ensure that no other branch can find it
    graph.artifacts("A", "0.0.0").depends("B", "0.0.0")
    graph.artifacts("B", "0.0.0").depends("C", "0.0.0")
    graph.artifacts("C", "0.0.0").depends("D", "0.0.0")
    graph.artifacts("D", "0.0.0").depends("A", "0.0.0")

    demands = [["A"]]

    result = sanitize_result Solve.it!(graph, demands)
    
    result.should eql({ "A" => "0.0.0",
                        "B" => "0.0.0",
                        "C" => "0.0.0",
                        "D" => "0.0.0"})

  end

  it "correctly resolves when a resolution exists but it is not the latest" do
    graph = Solve::Graph.new

    graph.artifacts("get-the-old-one", "1.0.0").depends("locked-mid-1", ">= 0.0.0").depends("locked-mid-2", ">= 0.0.0")
    graph.artifacts("get-the-old-one", "0.5.0")

    graph.artifacts("locked-mid-1", "2.0.0").depends("old-bottom", "= 2.0.0")
    graph.artifacts("locked-mid-1", "1.3.0").depends("old-bottom", "= 0.5.0")
    graph.artifacts("locked-mid-1", "1.0.0")

    graph.artifacts("locked-mid-2", "2.0.0").depends("old-bottom", "= 2.1.0")
    graph.artifacts("locked-mid-2", "1.4.0").depends("old-bottom", "= 0.5.0")
    graph.artifacts("locked-mid-2", "1.0.0")

    graph.artifacts("old-bottom", "2.1.0")
    graph.artifacts("old-bottom", "2.0.0")
    graph.artifacts("old-bottom", "1.0.0")
    graph.artifacts("old-bottom", "0.5.0")

    demands = [["get-the-old-one"]]

    result = sanitize_result Solve.it!(graph, demands)

    result.should eql({
      "get-the-old-one" => "1.0.0",
      "locked-mid-1" => "2.0.0",
      "locked-mid-2" => "1.0.0",
      "old-bottom" => "2.0.0"
    })
  end
end
