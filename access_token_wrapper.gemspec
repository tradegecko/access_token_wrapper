# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'access_token_wrapper/version'

Gem::Specification.new do |spec|
  spec.name          = "access_token_wrapper"
  spec.version       = AccessTokenWrapper::VERSION
  spec.authors       = ["Bradley Priest"]
  spec.email         = ["bradley@tradegecko.com"]
  spec.description   = %q{Wrapper for OAuth2::Token to automatically refresh the expiry token when expired.}
  spec.summary       = %q{Wrapper for OAuth2::Token to automatically refresh the expiry token when expired.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "oauth2"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "webmock"
end
