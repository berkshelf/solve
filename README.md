# Solve
[![Build Status](https://secure.travis-ci.org/reset/solve.png?branch=master)](http://travis-ci.org/reset/solve)
[![Dependency Status](https://gemnasium.com/reset/solve.png?travis)](https://gemnasium.com/reset/solve)

A Ruby constraint solver

## Installation

    $ gem install solve

## Usage

Create a new graph

    graph = Graph.new

Add an artifact to the graph

    graph.artifacts("nginx", "1.0.0")

Now add another artifact that has a dependency

    graph.artifacts("mysql", "1.2.4").depends("openssl", "~> 1.0.0")

Setup some demands

    graph.demands('nginx', '>= 0.100.0')

And now solve the graph

    Solve.it!(graph)

### Removing an artifact, demand, or dependency

    graph.artifacts("nginx", "1.0.0").delete

    graph.demands('nginx', '>= 0.100.0').delete

    artifact.dependencies("nginx", "~> 1.0.0").delete

## Authors

Author:: Jamie Winsor (<jamie@vialstudios.com>)

Copyright 2012 Jamie Winsor
