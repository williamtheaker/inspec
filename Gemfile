source "https://rubygems.org"

gem "inspec", path: "."

# This dependency is NOT used for normal gem deployment
# - instead, inspec-bin gemspec-depends on inspec
#
# However, AppBundler requires a top-level Gemfile.lock with inspec-bin
# in it in order to package the executable. Hence the odd backwards dependency.
gem "inspec-bin", path: "./inspec-bin"

gem "ffi", ">= 1.9.14", "!= 1.13.0", "!= 1.14.2"

# We have a build issue 2023-11-13 with unf_ext 0.0.9 so we are pinning to 0.0.8.2
# See https://github.com/knu/ruby-unf_ext/issues/74 https://buildkite.com/chef/inspec-inspec-inspec-5-omnibus-release/builds/22
gem "unf_ext", "= 0.0.8.2"

# inspec tests depend text output that changed in the 3.10 release
# but our runtime dep is still 3.9+
gem "rspec", ">= 3.10"

group :omnibus do
  gem "rb-readline"
  gem "appbundler"
  gem "ed25519" # ed25519 ssh key support done here as its a native gem we can't put in the gemspec
  gem "bcrypt_pbkdf" # ed25519 ssh key support done here as its a native gem we can't put in the gemspec
end

group :test do
  gem "chefstyle"
  gem "concurrent-ruby"
  gem "json_schemer"
  gem "m"
  gem "minitest-sprint", "~> 1.0"
  gem "minitest", "5.23.0"
  gem "mocha"
  gem "nokogiri"
  gem "pry-byebug"
  gem "pry"
  gem "rake"
  gem "simplecov"
  gem "simplecov_json_formatter"
  gem "webmock"
end

group :deploy do
  gem "inquirer"
end
