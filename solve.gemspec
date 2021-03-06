# -*- encoding: utf-8 -*-
require_relative "lib/solve/version"

Gem::Specification.new do |s|
  s.authors               = ["Jamie Winsor", "Andrew Garson", "Thibaud Guillaume-Gentil"]
  s.email                 = ["jamie@vialstudios.com", "agarson@riotgames.com", "thibaud@thibaud.me"]
  s.description           = %q{A Ruby version constraint solver}
  s.summary               = %q{A Ruby version constraint solver implementing Semantic Versioning 2.0.0-rc.1}
  s.homepage              = "https://github.com/berkshelf/solve"
  s.license               = "Apache-2.0"
  s.files                 = %w{LICENSE} + Dir.glob("lib/**/*")
  s.name                  = "solve"
  s.require_paths         = ["lib"]
  s.version               = Solve::VERSION
  s.required_ruby_version = ">= 2.1.0"

  s.add_dependency "semverse",     ">= 1.1", "< 4.0"
  s.add_dependency "molinillo",    "~> 0.6"

  s.add_development_dependency "thor"
  s.add_development_dependency "rake"
  s.add_development_dependency "spork"
  s.add_development_dependency "rspec"
end
