# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniship/version'

Gem::Specification.new do |spec|
  spec.name          = "omniship"
  spec.version       = Omniship::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Donavan White"]
  spec.email         = ["digi.cazter@gmail.com"]

  spec.summary       = "Shipping API for creating, tracking, and getting rates."
  spec.description   = "Create shipments and get rates and tracking info from various shipping carriers."
  spec.homepage      = "http://github.com/Digi-Cazter/omniship"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  
  spec.add_runtime_dependency "nokogiri", "~> 1.6", ">= 1.6.6.2"
end
