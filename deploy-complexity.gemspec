# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deploy_complexity/version'

Gem::Specification.new do |spec|
  spec.name          = "deploy-complexity"
  spec.version       = DeployComplexity::VERSION
  spec.license       = 'MIT'
  spec.authors       = ["Charles Comstock"]
  spec.email         = ["dgtized@gmail.com"]

  spec.summary       = "Analyze the history and complexity of upcoming and past deploys"
  spec.homepage      = "https://github.com/NoRedInk/deploy-complexity"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  spec.metadata['allowed_push_host'] = "NOWHERE!" if spec.respond_to? :metadata

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 13.0"

  spec.add_dependency "octokit", "~> 4.0"
  spec.add_dependency "slack-notifier", "~> 2.3.2"
  spec.add_dependency "values", "~> 1.8.0"

  spec.required_ruby_version = ">= 2.5"
end
