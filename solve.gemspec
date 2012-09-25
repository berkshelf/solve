# -*- encoding: utf-8 -*-
require File.expand_path('../lib/solve/gem_version', __FILE__)

Gem::Specification.new do |s|
  s.authors               = ["Jamie Winsor", "Andrew Garson"]
  s.email                 = ["jamie@vialstudios.com", "andrew.garson@gmail.com"]
  s.description           = %q{A Ruby constraint solver}
  s.summary               = s.description
  s.homepage              = "https://github.com/reset/solve"
  
  s.files                 = `git ls-files`.split($\)
  s.executables           = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files            = s.files.grep(%r{^spec/})
  s.name                  = "solve"
  s.require_paths         = ["lib"]
  s.version               = Solve::VERSION
  s.required_ruby_version = ">= 1.9.1"

  s.add_dependency 'json'

  s.add_development_dependency 'thor', '>= 0.16.0'
  s.add_development_dependency 'rake', '>= 0.9.2.2'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'fuubar'
  s.add_development_dependency 'spork'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'guard-spork'
  s.add_development_dependency 'guard-yard'
  s.add_development_dependency 'coolline'
end
