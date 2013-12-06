# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)
require "jullunch_daemon/version"

Gem::Specification.new do |s|
  s.name          = "jullunch_daemon"
  s.version       = JullunchDaemon::VERSION
  s.author        = "Peter Hellberg"
  s.email         = "peter.hellberg@athega.se"
  s.homepage      = "https://github.com/athega/jullunch_daemon"

  s.summary       = "Daemon that checks for new tweets, check ins and images."

  s.description   = "A small daemon (using foreverb) that handles tasks " +
                    "like updating the list of tweets, keeping track of " +
                    "check ins and uploaded images."

  s.files         = Dir["**/*"]
  s.executables   = %w[jullunch_daemon]
  s.require_paths = %w[lib]

  s.add_dependency "foreverb", "~> 0.3.2"
  s.add_dependency "yajl-ruby", "~> 1.1.0"
  s.add_dependency "rest-client", "~> 1.6.7"
  s.add_dependency "twitter-text", "1.7.0"
  s.add_development_dependency "minitest", "~> 5.1"
  s.add_development_dependency "mocha", "~> 0.14"
end
