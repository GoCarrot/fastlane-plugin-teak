# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/teak/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-teak'
  spec.version       = Fastlane::Teak::VERSION
  spec.author        = 'Pat Wilson'
  spec.email         = 'pat@teak.io'

  spec.summary       = 'Fastlane plugins for the Teak SDK'
  spec.homepage      = "https://github.com/GoCarrot/fastlane-plugin-teak"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  spec.add_runtime_dependency 'xcodeproj', '~> 1'

  spec.add_development_dependency 'pry', '~> 0'
  spec.add_development_dependency 'bundler', '>= 1.12'
  spec.add_development_dependency 'gem-release', '~> 2.0'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0'
  spec.add_development_dependency 'rake', '~> 12'
  spec.add_development_dependency 'rubocop', '~> 0'
  spec.add_development_dependency 'rubocop-require_tools', '~> 0'
  spec.add_development_dependency 'simplecov', '~> 0'
  spec.add_development_dependency 'fastlane', '~> 2.92', '>= 2.92.1'
end
