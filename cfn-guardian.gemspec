lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "cfnguardian/version"

Gem::Specification.new do |spec|
  spec.name          = "cfn-guardian"
  spec.version       = CfnGuardian::VERSION
  spec.authors       = ["Guslington"]
  spec.email         = ["itsupport@base2services.com"]

  spec.summary       = %q{Manages AWS cloudwatch alarms with default templates using cloudformation}
  spec.description   = %q{Manages AWS cloudwatch alarms with default templates using cloudformation}
  spec.homepage      = "https://github.com/base2Services/cfn-guardian"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/base2Services"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/base2Services/cfn-guardian"
  spec.metadata["changelog_uri"] = "https://github.com/base2Services/cfn-guardian"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 0.20"
  spec.add_dependency 'cfndsl', '~> 1.0', '<2'
  spec.add_dependency "terminal-table", '~> 1', '<2'
  spec.add_dependency 'term-ansicolor', '~> 1', '<2'
  spec.add_dependency 'aws-sdk-s3', '~> 1.60', '<2'
  spec.add_dependency 'aws-sdk-cloudformation', '~> 1.31', '<2'
  spec.add_dependency 'aws-sdk-cloudwatch', '~> 1.28', '<2'
  spec.add_dependency 'aws-sdk-codecommit', '~> 1.28', '<2'
  spec.add_dependency 'aws-sdk-codepipeline', '~> 1.28', '<2'
  
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
