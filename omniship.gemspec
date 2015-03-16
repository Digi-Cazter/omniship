lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'omniship/version'

Gem::Specification.new do |s|
  s.name        = "omniship"
  s.version     = Omniship::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Donavan White"]
  s.email       = ["digi.cazter@gmail.com"]
  s.homepage    = "http://github.com/Digi-Cazter/omniship"
  s.summary     = "Shipping API for creating, tracking, and getting rates."
  s.description = "Create shipments and get rates and tracking info from various shipping carriers."
  s.license     = "MIT"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_runtime_dependency 'activesupport', '~> 2.3', '>= 2.3.5'
  s.add_runtime_dependency 'i18n', '~> 0'
  s.add_runtime_dependency 'active_utils', '~> 1.0', '>= 1.0.1'
  s.add_runtime_dependency 'builder', '~> 0'
	s.add_runtime_dependency 'nokogiri', '~> 0'

  s.add_development_dependency 'rake', '~> 0'
  s.add_development_dependency 'mocha', '~> 0'
  s.add_development_dependency 'railties', '~> 0'
  s.add_development_dependency 'rails', '~> 0'

  s.files        = Dir.glob("lib/**/*") + %w(MIT-LICENSE README.markdown CHANGELOG)
  s.require_path = 'lib'
end
