# Solve

TODO: Write a gem description

## Installation

    $ gem install solve

## Usage

    graph = Graph.new
    graph.artifacts("nginx", "1.0.0").depends("nginx", "~> 1.0.0")
    graph.demands('nginx', '>= 0.100.0')

    Solve.it!(graph)

### Removing an artifact, demand, or dependency

    graph.artifacts("nginx", "1.0.0").delete

    graph.demands('nginx', '>= 0.100.0').delete

    artifact.dependencies("nginx", "~> 1.0.0").delete

### Removing an artifact

## Neckbeard Usage

  graph = Graph.new
  artifact = Artifact.new(graph)
  graph.add_artifact(artifact)

## Authors

Author:: Jamie Winsor (<jamie@vialstudios.com>)

Copyright 2012 Jamie Winsor
