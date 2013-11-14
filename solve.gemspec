# -*- encoding: utf-8 -*-
require File.expand_path('../lib/solve/gem_version', __FILE__)

Gem::Specification.new do |s|
  s.authors               = ["Jamie Winsor", "Andrew Garson", "Thibaud Guillaume-Gentil"]
  s.email                 = ["jamie@vialstudios.com", "agarson@riotgames.com", "thibaud@thibaud.me"]
  s.description           = %q{A Ruby version constraint solver}
  s.summary               = %q{A Ruby version constraint solver implementing Semantic Versioning 2.0.0-rc.1}
  s.homepage              = "https://github.com/berkshelf/solve"
  s.license               = "Apache 2.0"

  s.files                 = `git ls-files`.split($\)
  s.executables           = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files            = s.files.grep(%r{^spec/})
  s.name                  = "solve"
  s.require_paths         = ["lib"]
  s.version               = Solve::VERSION
  s.required_ruby_version = ">= 1.9.1"
end
