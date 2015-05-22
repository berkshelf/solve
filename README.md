# Solve
[![Gem Version](http://img.shields.io/gem/v/solve.svg)][gem]
[![Build Status](http://img.shields.io/travis/berkshelf/solve.svg)][travis]

[gem]: https://rubygems.org/gems/solve
[travis]: http://travis-ci.org/berkshelf/solve

A Ruby versioning constraint solver implementing [Semantic Versioning 2.0.0](http://semver.org).

## Installation

    $ gem install solve

## Usage

Create a new graph

    graph = Solve::Graph.new

Add an artifact to the graph

    graph.artifact("nginx", "1.0.0")

Now add another artifact that has a dependency

    graph.artifact("mysql", "1.2.4-alpha.1").depends("openssl", "~> 1.0.0")

Dependencies can be chained, too

    graph.artifact("ntp", "1.0.0").depends("build-essential").depends("yum")

And now solve the graph with some demands

    Solve.it!(graph, [['nginx', '>= 0.100.0']])

Or, if you want a topologically sorted solution
NOTE: This will raise Solve::Errors::UnsortableSolutionError if the solution contains a cycle (which can happen with ruby packages)

    Solve.it!(graph, [['nginx', '>= 0.100.0']], sorted: true)


### Selecting A Resolver

Solve supports two different resolvers. A pure Ruby solver implemented using [Molinillo](https://github.com/CocoaPods/Molinillo) and the same dependency resolver the Chef Server uses, [dep-selector](https://github.com/chef/dep-selector), which is a Ruby C extension for [Gecode](https://github.com/ampl/gecode).

You can set the resolver by calling `Solver.engine=` with the symbol `:ruby` or `:gecode`.

```ruby
    Solver.engine = :ruby
    Solver.engine = :gecode
```

The Ruby solver is installed and enabled by default. If you'd like to use the Gecode solver you can do so by installing the dep-selector gem or adding it to your Gemfile:

    $ gem install dep_selector

### Increasing the solver's timeout

By default the solver will wait 30 seconds before giving up on finding a solution. Under certain conditions a graph may be too complicated to solve within the alotted time. To increase the timeout you can set the "SOLVE_TIMEOUT" environment variable to the amount of seconds desired.

    $ export SOLVE_TIMEOUT=60

This will set the timeout to 60 seconds instead of the default 30 seconds.

## Authors

* [Jamie Winsor](https://github.com/reset) (<jamie@vialstudios.com>)
* [Andrew Garson](andrewGarson) (<agarson@riotgames.com>)
* [Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](http://twitter.com/thibaudgg))
