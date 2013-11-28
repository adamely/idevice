# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'idev/version'

Gem::Specification.new do |spec|
  spec.name          = "idev"
  spec.version       = Idev::VERSION
  spec.authors       = ["Eric Monti"]
  spec.email         = ["monti@bluebox.com"]
  spec.description   = %q{Ruby FFI bindings for libimobiledevice}
  spec.summary       = %q{Ruby FFI bindings for libimobiledevice}
  spec.homepage      = ""
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
