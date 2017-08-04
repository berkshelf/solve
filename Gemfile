source "https://rubygems.org"

gemspec

group :gecode do
  gem "dep_selector", "~> 1.0"
end

# If this group is named "development", then `bundle install --without
# development` automagically excludes development dependencies that are listed
# in the gemspec, which will skip installing rspec and then we can't run tests.
group :development do
  gem "fuubar"
  gem "yard"
  gem "redcarpet"
  gem "chefstyle", git: "https://github.com/chef/chefstyle"
end

group :guard do
  gem "guard-rspec"
  gem "guard-spork"
  gem "guard-yard"
  gem "coolline"

  require "rbconfig"

  if RbConfig::CONFIG["target_os"] =~ /darwin/i
    gem "ruby_gntp", require: false

  elsif RbConfig::CONFIG["target_os"] =~ /linux/i
    gem "libnotify", require: false

  elsif RbConfig::CONFIG["target_os"] =~ /mswin|mingw/i
    gem "win32console", require: false
  end
end
