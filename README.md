# Solve
[![Build Status](https://secure.travis-ci.org/reset/solve.png?branch=master)](http://travis-ci.org/reset/solve)
[![Dependency Status](https://gemnasium.com/reset/solve.png?travis)](https://gemnasium.com/reset/solve)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/reset/solve)

A Ruby versioning constraint solver implementing [Semantic Versioning 2.0.0-rc.1](http://semver.org).

Maintained by the RightScale Teal Team

## Installation

    $ gem install solve

## Usage

Create a new graph

    graph = Graph.new

Add an artifact to the graph

    graph.artifacts("nginx", "1.0.0")

Now add another artifact that has a dependency

    graph.artifacts("mysql", "1.2.4-alpha.1").depends("openssl", "~> 1.0.0")

Dependencies can be chained, too

    graph.artifacts("ntp", "1.0.0").depends("build-essential").depends("yum")

And now solve the graph with some demands

    Solve.it!(graph, ['nginx', '>= 0.100.0'])

### Removing an artifact, or dependency from the graph

    graph.artifacts("nginx", "1.0.0").delete

    artifact.dependencies("nginx", "~> 1.0.0").delete

## Authors

Author:: Jamie Winsor (<jamie@vialstudios.com>)
Author:: Andrew Garson (<andrew.garson@gmail.com>)

## Contributors

[Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](http://twitter.com/thibaudgg))
