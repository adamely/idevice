# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'idevice/version'

Gem::Specification.new do |spec|
  spec.name          = "idevice"
  spec.version       = Idevice::VERSION
  spec.authors       = ["Eric Monti"]
  spec.email         = ["esmonti@gmail.com"]
  spec.description   = %q{Ruby FFI bindings for libimobiledevice}
  spec.summary       = %q{
Ruby FFI bindings for libimobiledevice.

The ruby Idevice library was written primarily as a research tool for
prototyping iOS tools that use USB as well as a tool to aid in 
reverse-engineering new areas of the iOS USB protocols.
}
  spec.homepage      = "https://github.com/emonti/idevice"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi"
  spec.add_dependency "plist"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
