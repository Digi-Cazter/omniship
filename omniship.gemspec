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

  s.add_runtime_dependency 'activesupport', '~> 4.2', '>= 2.3.5'
  s.add_runtime_dependency 'i18n', '~> 0.7', '>= 0.7.0'
  s.add_runtime_dependency 'active_utils', '~> 3.0', '>= 3.0.0'
  # s.add_runtime_dependency 'builder', '~> 3.2', '>= 3.2.2'
  s.add_runtime_dependency 'nokogiri', '~> 1.6', '>= 1.6.6.2'


  s.add_development_dependency 'minitest', '~> 5.9.0'
  s.add_development_dependency 'minitest-line', '~> 0.6.3'
  s.add_development_dependency 'minitest-reporters', '~> 1.1.9'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rake', '~> 10.4', '>= 10.4.2'
  s.add_development_dependency 'mocha', '~> 1.1', '>= 1.1.0'
  # s.add_development_dependency 'railties', '~> 4.2', '>= 4.2'
  s.add_development_dependency 'rails', '~> 4.2', '>= 4.2'

  s.files        = Dir.glob("lib/**/*") + %w(MIT-LICENSE README.markdown CHANGELOG)
  s.require_path = 'lib'
end
