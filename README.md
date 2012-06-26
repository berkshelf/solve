# Solve

TODO: Write a gem description

## Installation

    $ gem install solve

## Usage

    graph = Graph.new
    graph.aritfact("nginx", "1.0.0").depends("nginx", "~> 1.0.0")
    graph.demand('nginx', '>= 0.100.0')

    Solve.it!(graph)

### Removing an artifact, demand, or dependency

    graph.aritfact("nginx", "1.0.0").delete

    graph.demand('nginx', '>= 0.100.0').delete

    artifact.dependencies("nginx", "~> 1.0.0").delete

### Removing an artifact

## Authors

Author:: Jamie Winsor (<jamie@vialstudios.com>)

Copyright 2012 Jamie Winsor
