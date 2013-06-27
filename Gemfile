source 'https://rubygems.org'

gemspec

group :development do
  gem 'fuubar'
  gem 'yard'
  gem 'redcarpet'
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'guard-yard'
  gem 'coolline'

  require 'rbconfig'

  if RbConfig::CONFIG['target_os'] =~ /darwin/i
    gem 'ruby_gntp', require: false

  elsif RbConfig::CONFIG['target_os'] =~ /linux/i
    gem 'libnotify', require: false

  elsif RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
    gem 'win32console', require: false
  end
end

group :test do
  gem 'thor', '>= 0.16.0'
  gem 'rake', '>= 0.9.2.2'

  gem 'spork'
  gem 'rspec'
end
