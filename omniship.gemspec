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

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency('activesupport', '>= 2.3.5')
  s.add_dependency('rails')
  s.add_dependency('i18n')
  s.add_dependency('active_utils', '>= 1.0.1')
  s.add_dependency('builder')
	s.add_dependency('nokogiri')

  s.add_development_dependency('rake')
  s.add_development_dependency('mocha')

  s.files        = Dir.glob("lib/**/*") + %w(MIT-LICENSE README.markdown CHANGELOG)
  s.require_path = 'lib'
end
