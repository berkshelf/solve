# Solve
[![Gem Version](https://badge.fury.io/rb/solve.png)](http://badge.fury.io/rb/solve)
[![Build Status](https://secure.travis-ci.org/berkshelf/solve.png?branch=master)](http://travis-ci.org/berkshelf/solve)

A Ruby versioning constraint solver implementing [Semantic Versioning 2.0.0](http://semver.org).

## Installation

    $ gem install solve

## Usage

Create a new graph

```ruby
graph = Graph.new
```

Add an artifact to the graph

```ruby
graph.artifact("nginx", "1.0.0")
```

Now add another artifact that has a dependency

```ruby
graph.artifact("mysql", "1.2.4-alpha.1").depends("openssl", "~> 1.0.0")
```

Dependencies can be chained, too

```ruby
graph.artifact("ntp", "1.0.0")
  .depends("build-essential")
  .depends("yum", ">= 1.0.0")
```

And now solve the graph with some demands

```ruby
Solve.it!(graph, ['nginx', '>= 0.100.0'])
```

Or, if you want a topologically sorted solution
NOTE: This will raise Solve::Errors::UnsortableSolutionError if the solution contains a cycle (which can happen with Ruby packages)

```ruby
Solve.it!(graph, ['nginx', '>= 0.100.0'], sorted: true)
```

## Authors

* [Seth Vargo](https://github.com/sethvargo) (<sethvargo@gmail.com>)
* [Jamie Winsor](https://github.com/reset) (<jamie@vialstudios.com>)
* [Andrew Garson](andrewGarson) (<agarson@riotgames.com>)
* [Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](http://twitter.com/thibaudgg))
